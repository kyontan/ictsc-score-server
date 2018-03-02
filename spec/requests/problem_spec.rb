require_relative '../spec_helper.rb'

describe Problem do
  include ApiHelpers

  before(:each) {
    allow(Setting).to receive(:competition_start_at).and_return(DateTime.now - 3.year)
  }

  describe 'GET /api/problems' do
    let!(:problem) { create(:problem) }
    let!(:next_problem) { create(:problem, problem_must_solve_before: problem) }

    let(:response) { get '/api/problems' }
    subject { response.status }

    by_nologin     { is_expected.to eq 200 }
    by_viewer      { is_expected.to eq 200 }
    by_participant { is_expected.to eq 200 }
    by_writer      { is_expected.to eq 200 }
    by_admin       { is_expected.to eq 200 }

    describe '#size' do
      subject { json_response.size }

      by_nologin     { is_expected.to eq 0 }
      by_viewer      { is_expected.to eq 2 }
      by_participant { is_expected.to eq 2 }
      by_writer      { is_expected.to eq 2 }
      by_admin       { is_expected.to eq 2 }
    end

    let(:expected_keys) { %w(id title text solved_teams_count creator_id created_at updated_at problem_must_solve_before_id reference_point perfect_point problem_group_ids team_private order) }
    describe '#keys for problem' do
      let(:json_response_problem) { json_response.find{|p| p['id'] == problem.id } }
      subject { json_response_problem.keys }

      by_viewer      { is_expected.to match_array expected_keys }
      by_participant { is_expected.to match_array expected_keys - ['creator_id'] }
      by_writer      { is_expected.to match_array expected_keys }
      by_admin       { is_expected.to match_array expected_keys }

      describe '#solved_teams_count (delay)' do
        let!(:score_by_other_team_a) { create(:score, point: problem.reference_point, solved: true, answer: create(:answer, problem: problem)) } # solved
        let!(:score_by_other_team_b) { create(:score, point: problem.reference_point - 1, solved: false, answer: create(:answer, problem: problem)) } # not solved
        subject { json_response_problem['solved_teams_count'] }

        by_viewer      { is_expected.to eq 1 }
        by_participant { is_expected.to eq 0 }
        by_writer      { is_expected.to eq 1 }
        by_admin       { is_expected.to eq 1 }
      end

      describe '#solved_teams_count (opened)' do
        delayed = DateTime.now - Setting.answer_reply_delay_sec.seconds
        let!(:score_by_other_team_a) { create(:score, point: problem.reference_point, solved: true, answer: create(:answer, problem: problem, created_at: delayed)) } # solved
        let!(:score_by_other_team_b) { create(:score, point: problem.reference_point - 1, solved: false, answer: create(:answer, problem: problem, created_at: delayed)) } # not solve subject
        subject { json_response_problem['solved_teams_count'] }

        by_viewer      { is_expected.to eq 1 }
        by_participant { is_expected.to eq 1 }
        by_writer      { is_expected.to eq 1 }
        by_admin       { is_expected.to eq 1 }
      end
    end

    describe "#keys for problem participant haven't solve problem before" do
      let(:expected_keys_for_participant) { expected_keys - %w(title text) }
      let(:json_response_next_problem) { json_response.find{|p| p['id'] == next_problem.id } }
      subject { json_response_next_problem.keys }

      by_participant { is_expected.to match_array expected_keys_for_participant - ['creator_id'] }
    end
  end

  describe 'GET /api/problems/:id' do
    let!(:problem) { create(:problem) }
    let!(:next_problem) { create(:problem, problem_must_solve_before: problem) }

    let(:response) { get "/api/problems/#{problem.id}" }
    subject { response.status }

    by_nologin     { is_expected.to eq 404 }
    by_viewer      { is_expected.to eq 200 }
    by_writer      { is_expected.to eq 200 }
    by_admin       { is_expected.to eq 200 }

    describe "problem have solved by other team before problem must solve" do
      let(:team) { create(:team) }
      let!(:score) { create(:score, answer: create(:answer, problem: problem, team: team), point: problem.reference_point) }
      let(:response) { get "/api/problems/#{next_problem.id}" }
      subject { response.status }

      by_participant { is_expected.to eq 200 }
    end

    describe "problem haven't solved before problem must solve" do
      let!(:problem) { create(:problem) }
      let(:response) { get "/api/problems/#{next_problem.id}" }
      subject { response.status }

      by_participant { is_expected.to eq 404 }
    end

    describe '#keys' do
      let(:expected_keys) { %w(id title text solved_teams_count creator_id created_at updated_at problem_must_solve_before_id reference_point perfect_point problem_group_ids team_private order) }
      subject { json_response.keys }
      by_viewer      { is_expected.to match_array expected_keys }
      by_writer      { is_expected.to match_array expected_keys }
      by_admin       { is_expected.to match_array expected_keys }
    end

    describe '#solved_teams_count' do
      let!(:score_by_other_team_a) { create(:score, point: problem.reference_point, answer: create(:answer, problem: problem)) } # solved
      let!(:score_by_other_team_b) { create(:score, point: problem.reference_point - 1, answer: create(:answer, problem: problem)) } # not solved
      subject { json_response['solved_teams_count'] }

      by_viewer      { is_expected.to eq 1 }
      by_participant { is_expected.to eq 1 }
      by_writer      { is_expected.to eq 1 }
      by_admin       { is_expected.to eq 1 }
    end
  end

  describe 'POST /api/problems' do
    let(:problem) { build(:problem) }

    let(:params) do
      {
        title: problem.title,
        text: problem.text,
        creator_id: problem.creator_id,
        reference_point: problem.reference_point,
        perfect_point: problem.perfect_point,
        problem_group_ids: problem.problem_group_ids,
      }
    end

    describe 'create problem' do
      let(:expected_keys) { %w(id title text creator_id created_at updated_at problem_must_solve_before_id reference_point perfect_point problem_group_ids team_private order) }
      let(:response) { post '/api/problems', params }
      subject { response.status }

      by_nologin     { is_expected.to eq 403 }
      by_viewer      { is_expected.to eq 403 }
      by_participant { is_expected.to eq 403 }

      all_success_block = Proc.new do
        is_expected.to eq 201
        expect(json_response.keys).to match_array expected_keys
      end

      by_writer &all_success_block
      by_admin &all_success_block
    end

    describe 'create problem with missing title' do
      let(:params_without_title) { params.except(:title) }
      let(:response) { post '/api/problems', params_without_title }
      subject { response.status }

      by_writer      { is_expected.to eq 400 }
      by_admin       { is_expected.to eq 400 }
    end
  end

  describe 'PUT, PATCH /api/problems' do
    let(:creator) do
      if current_member&.role == build(:role, :writer)
        current_member
      else
        build(:member, :writer)
      end
    end
    let!(:problem) { create(:problem, creator: creator) }
    let(:new_title) { problem.title + 'nya-' }

    describe "edit problem" do
      let(:params) do
        {
          title: new_title,
          text: problem.text,
          creator_id: problem.creator_id,
          reference_point: problem.reference_point,
          perfect_point: problem.perfect_point,
          problem_group_ids: problem.problem_group_ids,
          problem_must_solve_before_id: problem.problem_must_solve_before_id
        }
      end

      shared_examples 'expected success statuses' do
        subject { response.status }

        by_nologin     { is_expected.to eq 404 }
        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }
        by_writer      { is_expected.to eq 200 }
        by_admin       { is_expected.to eq 200 }
      end

      context 'PUT without title' do
        let(:response) { put "/api/problems/#{problem.id}", params.except(:title) }
        subject { response.status }

        by_nologin     { is_expected.to eq 404 }
        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }
        by_writer      { is_expected.to eq 400 }
        by_admin       { is_expected.to eq 400 }
      end

      context 'PATCH without title' do
        let(:response) { patch "/api/problems/#{problem.id}", params.except(:title) }
        it_behaves_like 'expected success statuses'

        by_writer      { expect(json_response['title']).to eq problem.title }
        by_admin       { expect(json_response['title']).to eq problem.title }
      end

      context 'PUT' do
        let(:response) { put "/api/problems/#{problem.id}", params }
        it_behaves_like 'expected success statuses'

        by_writer      { expect(json_response['title']).to eq new_title }
        by_admin       { expect(json_response['title']).to eq new_title }
      end
    end
  end

  describe 'DELETE /api/problems/:id' do
    let(:creator) do
      if current_member&.role == build(:role, :writer)
        current_member
      else
        build(:member, :writer)
      end
    end
    let!(:problem) { create(:problem, creator: creator) }
    let(:response) { delete "/api/problems/#{problem.id}" }
    subject { response.status }

    by_nologin     { is_expected.to eq 404 }
    by_viewer      { is_expected.to eq 404 }
    by_participant { is_expected.to eq 404 }
    by_writer      { is_expected.to eq 204 }
    by_admin       { is_expected.to eq 204 }

    describe "can't delete problems created by others" do
      let!(:problem) { create(:problem) }
      let(:response) { delete "/api/problems/#{problem.id}" }
      subject { response.status }

      by_writer      { is_expected.to eq 404 }
    end
  end
end
