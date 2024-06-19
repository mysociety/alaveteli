##
# Projects controller, for pro user self serve projects.
#
class AlaveteliPro::ProjectsController < AlaveteliPro::BaseController
  def index
    @projects = current_user.projects.owner.paginate(
      page: params[:page], per_page: 10
    )
  end
end
