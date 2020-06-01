RSpec.shared_context 'Project::Queue context' do
  let(:project) do
    FactoryBot.create(:project,
                      contributors_count: 2,
                      classifiable_requests_count: 2,
                      extractable_requests_count: 2)
  end

  let(:current_user) { project.contributors.last }

  let(:session) { { user_id: current_user.id } }

  let(:queue) { described_class.new(project, session) }
end
