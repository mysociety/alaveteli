##
# Controller for managing Project::Submissions from the admin interface
#
class Admin::Projects::SubmissionsController < AdminController
  before_action :set_submission, only: :destroy

  def destroy
    @submission.destroy
    redirect_to admin_project_path(@submission.project),
                notice: 'Submission successfully deleted.'
  end

  private

  def set_submission
    @submission = Project::Submission.find(params[:id])
  end
end
