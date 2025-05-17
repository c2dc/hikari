from flask import render_template, request, redirect, url_for, flash, Blueprint
import random
from sqlalchemy.exc import IntegrityError
from CTFd.plugins import register_plugin_assets_directory
from CTFd.utils.decorators import admins_only
from CTFd.models import Teams
from CTFd.models import Users
from CTFd.models import db
from .hikari_models import ZerotierConfig
from .hikari_forms import ZerotierForm, SetupFirstChallengeForm, NotifyCompetitorsForm, ImportHikariCTFdForm, NotifyMultipleCompetitorsForm
from CTFd.plugins.hikari_challenge import HikariController, HikariChallengeModel
from CTFd.forms import BaseForm
from CTFd.utils.email import sendmail
from CTFd.utils.config import get_app_config
from .hikari_importer import HikariImporter
from werkzeug.utils import secure_filename
from flask import current_app
import os

def load(app):
    # Create all tables 
    app.db.create_all()


    # Register plugin assets directory
    register_plugin_assets_directory(app, base_path='/plugins/hikari-plugin/assets/')

    hikariplugin = Blueprint('hikariplugin', __name__, template_folder="templates")

    @hikariplugin.route('/admin/hikari/init-competition', methods=['GET'])
    @admins_only
    def init_competition():
      
        # If the competition is already running, no need to start it again.
        if check_competition_status()['status'] == 'Ok':
            return redirect(url_for('hikariplugin.hikari_main'))
        
        challs = list(HikariChallengeModel.query.all())
        for chall in challs:
            if chall.requirements and len(set(chall.requirements.get("prerequisites"))) != 0:
                continue
            else:
                # Activate logs for the challenges that do not have prerequisites
                # and are visible
                if chall.state == 'visible':
                    print("ACTIVATING LOGS FOR CHALLENGE: ", chall.name)
                    HikariController.activate_logs(chall.id)
                    setattr(chall, "logs_activated", True)
                    db.session.commit()

        return redirect(url_for('hikariplugin.hikari_main'))
    
    @hikariplugin.route('/admin/hikari/reset-competition', methods=['GET'])
    @admins_only
    def reset_competition():
        if not check_competition_status():
            return redirect(url_for('hikari_main'))

        # Reset all challenges
        challenges = HikariChallengeModel.query.all()
        for c in challenges:
            c.logs_activated = False
            c.is_first_challenge = False
        db.session.commit()

        return redirect(url_for('hikariplugin.hikari_main'))


    def check_all():
        if (check_teams_status())['status'] == 'error':
            return False
        if (check_zerotiers())['status'] == 'error':
            return False
        
        return True

    def check_teams_status():
        teams = Teams.query.all()
        zerotiers = ZerotierConfig.query.all()

        team_ids = set([t.id for t in teams])
        zerotier_team_ids = set([z.team_id for z in zerotiers])

        if len(team_ids.difference(zerotier_team_ids)) != 0:
            return {"message":"There are teams that do not have zerotiers associated with it.", "status":"warning", "class":"hikari-warning"}

        return {"message": "Ok", "status":"Ok", "class":"hikari-success"}

    def check_zerotiers():
        zerotiers = ZerotierConfig.query.all()
        if len(zerotiers) == 0:
            return {"message": "No zerotiers registered", "status":"warning", "class":"hikari-warning"}

        return {"message": "Ok", "status":"Ok", "class":"hikari-success"}

    def check_competition_status():
        if check_all():
            chall = HikariChallengeModel.query.filter_by(logs_activated=True).first()
            if chall and chall.logs_activated:
                return {"message":"Ok", "status":"Started", "class":"hikari-success"}
        return {"message":"Not running", "status":"Not running", "class":"hikari-error"}

    # Route: main page
    @hikariplugin.route('/admin/hikari', methods=['GET'])
    @admins_only
    def hikari_main():

        # Load them on main page
        stats = dict()
        stats['zerotier'] = check_zerotiers()
        stats['teams'] = check_teams_status()
        stats['competition'] = check_competition_status()

        return render_template('hikari-page.html', stats=stats)
    
    # Route: notification page
    @hikariplugin.route('/admin/hikari-notify', methods=['GET', 'POST'])
    @admins_only
    def hikari_notify():
        form = NotifyMultipleCompetitorsForm(request.form)
        if request.method == 'POST' and form.validate():
            message = form.message.data
            team_ids    = form.team_selection.data
            users = list()

            # Gather users from the specified team
            for team_id in team_ids:
                _users   = Users.query.filter_by(team_id=team_id).all()
                users += _users

            # Get emails belonging to the users
            emails = [u.email for u in users]

            # Send to `emails` list
            for email in emails:
                sendmail(email, message)
            return redirect(url_for('hikariplugin.hikari_main'))
        else:
            teams = Teams.query.all()
            return render_template('hikari-notify.html', teams=teams, form=form)

    # POST-Route: Route that sends zerotier configurations to all users
    @hikariplugin.route('/admin/hikari-notify-all', methods=['POST'])
    @admins_only
    def hikari_notify_all():
        users = Users.query.all()
        
        for user in users:
            team_id = user.team_id
            team_zerotier_config = ZerotierConfig.query.filter_by(team_id=team_id).first()
            if team_zerotier_config:
                message = "Greetings competitor! You may have access to Kibana and other resources by joining this zerotier id: {}".format(team_zerotier_config.network_id)
                sendmail(user.email, message)
        return redirect(url_for('hikariplugin.hikari_zerotier_setup'))
    
    # Route: Zerotier administration page
    @hikariplugin.route('/admin/hikari-zerotier-setup', methods=['GET', 'POST'])
    @admins_only
    def hikari_zerotier_setup():
        teams = Teams.query.all()
        zerotiers = ZerotierConfig.query.all()
        _dummyForm = BaseForm()
        return render_template('hikari-zerotier.html', teams=teams, zerotier_configs=zerotiers, form=_dummyForm)
    
    
    # POST-Route: Route that sets zerotier configuration
    @hikariplugin.route('/admin/set-zerotier-config', methods=['POST'])
    @admins_only
    def set_zerotier_config():
        team_id = request.form.get('team_id')
        network_id = request.form.get('network_id')
    
        config = ZerotierConfig.query.filter_by(network_id=network_id).first()
        team = Teams.query.filter_by(id=team_id).first()
        is_team_associated = ZerotierConfig.query.filter_by(team_id=team_id).first()
        if config:
            try:
                if is_team_associated:
                    is_team_associated.team_id = None
                    db.session.commit()

                config.team_id = team_id
                db.session.commit()
                flash('Zerotier associated for team \'{}\''.format(team.name), 'success')
            except IntegrityError as e:
                db.session.rollback()
                flash('Error while associating zerotier for team {}: {}'.format(team.name, e), 'danger')
                return redirect(url_for('hikariplugin.hikari_zerotier_setup'))
        return redirect(url_for('hikariplugin.hikari_zerotier_setup'))
        

    # POST-Route: Route that unlinks a zerotier from a team
    @hikariplugin.route('/admin/hikari-zerotier-unlink', methods=['POST'])
    @admins_only
    def delete_zerotier_assoc():
        team_id = request.form.get('team_id')
        if not team_id:
            return redirect(url_for('hikariplugin.hikari_zerotier_setup'))

        config = ZerotierConfig.query.filter_by(team_id=team_id).first()
        if config:
            config.team_id = None
            db.session.commit()
        return redirect(url_for('hikariplugin.hikari_zerotier_setup'))

    # Route: Page for creating zerotiers
    @hikariplugin.route('/admin/hikari-create-zerotier', methods=['GET', 'POST'])
    @admins_only
    def create_zerotier():
        form = ZerotierForm(request.form)
        if request.method == 'POST' and form.validate():
            team_id = None
            network_id = form.network_id.data
            name = form.name.data

            new_config = ZerotierConfig(team_id=team_id, network_id=network_id, name=name)
            db.session.add(new_config)
            db.session.commit()
            
            flash('Zerotier \'{}\' created'.format(name), 'success')
            return redirect(url_for('hikariplugin.create_zerotier'))
        return render_template('hikari-zerotier-create.html', form=form)
    
    # POST-Route: Route that deletes a zerotier from the database
    @hikariplugin.route('/admin/hikari-delete-zerotier', methods=['POST'])
    @admins_only
    def delete_zerotier():
        network_id = request.form.get('network_id')
        zerotier = ZerotierConfig.query.filter_by(network_id=network_id).first()
        if zerotier:
            db.session.delete(zerotier)
            flash('Zerotier \'{}\' deleted'.format(zerotier.name), 'success')
            db.session.commit()
        else:
            flash('Zerotier not found', 'danger')
        
        return redirect(url_for('hikariplugin.hikari_zerotier_setup'))


    # POST-Route: Route that randomly assigns zerotiers to teams
    @hikariplugin.route('/admin/hikari-zerotier-random-assign', methods=['POST'])
    @admins_only
    def hikari_zerotier_random_assign():
        teams = Teams.query.all()
        zerotiers = ZerotierConfig.query.all()

        if len(teams) != len(zerotiers):
            flash('Error: The number of zerotiers ({}) is not the same number as the teams ({})'.format(len(zerotiers), len(teams)), 'danger')
            return redirect(url_for('hikariplugin.hikari_zerotier_setup'))
        
        random.shuffle(teams)
        random.shuffle(zerotiers)

        for z in zerotiers:
            z.team_id = None

        db.session.commit()

        for t, z in zip(teams, zerotiers):
            z.team_id = t.id

        try:
            db.session.commit()
            flash('All zerotiers were randomly associated to a team', 'success')
        except Exception as e:
            flash('Error while assigning zerotiers: {}'.format(e), 'danger')
        return redirect(url_for('hikariplugin.hikari_zerotier_setup'))

    # POST-Route: Route that unlinks all zerotiers
    @hikariplugin.route('/admin/hikari-zerotier-unlink-all', methods=['POST'])
    @admins_only
    def hikari_unlink_all_zerotiers():
        zerotiers = ZerotierConfig.query.all()
        for z in zerotiers:
            z.team_id = None
        
        try:
            db.session.commit()
            flash('All zerotiers were unlinked', 'success')
        except Exception as e:
            flash('Error while unlinking zerotiers: {}'.format(e), 'danger')
        return redirect(url_for('hikariplugin.hikari_zerotier_setup'))

#    POST-Route: Route that deletes all zerotiers
    @hikariplugin.route('/admin/delete-all-zerotiers', methods=['POST'])
    @admins_only
    def hikari_delete_all_zerotiers():
        zerotiers = ZerotierConfig.query.all()
        for z in zerotiers:
            db.session.delete(z)
        
        try:
            db.session.commit()
            flash('All zerotiers were deleted', 'success')
        except Exception as e:
            flash('Error while deleting zerotiers: {}'.format(e), 'danger')
        return redirect(url_for('hikariplugin.hikari_zerotier_setup'))


    @hikariplugin.route('/admin/import-hikari-ctf', methods=['GET', 'POST'])
    @admins_only
    def hikari_import_ctf():
        form = ImportHikariCTFdForm()
        
        if form.validate_on_submit():
            file = form.file_import.data
            if file:
                filename = secure_filename(file.filename)
                upload_path = os.path.join("/tmp", filename)
                print(upload_path)
                file.save(upload_path)

                importer = HikariImporter(upload_path)
                importer.import_all()

                return redirect(url_for('hikariplugin.hikari_main'))
        else:
            return render_template('hikari-import.html', form=form)
    app.register_blueprint(hikariplugin)

