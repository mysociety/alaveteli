# View and manage Project Leaderboards
class Projects::LeaderboardsController < Projects::BaseController
  skip_before_action :html_response

  def show
    authorize! :export, @project

    respond_to do |format|
      format.csv do
        leaderboard = Project::Leaderboard.new(@project)
        send_data leaderboard.to_csv, filename: leaderboard.name,
          type: 'text/csv'
      end
    end
  end
end
