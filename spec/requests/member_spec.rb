require_relative '../spec_helper.rb'

describe Member do
  include ApiHelpers

  describe 'GET /api/members' do
    let!(:viewer)      { create(:member, :viewer) }
    let!(:participant) { create(:member, :participant) }
    let!(:writer)      { create(:member, :writer) }
    let!(:admin)       { create(:member, :admin) }

    describe '/api/members' do
      let(:response) { get '/api/members' }
      subject { response.status }

      by_nologin     { is_expected.to eq 200 }
      by_viewer      { is_expected.to eq 200 }
      by_participant { is_expected.to eq 200 }
      by_writer      { is_expected.to eq 200 }
      by_admin       { is_expected.to eq 200 }

      describe '#size' do
        subject { json_response.map{|x| x["role_id"] }.uniq }
        by_nologin     { is_expected.to match_array [] }
        by_participant { is_expected.to match_array [participant].map(&:role_id) }
        by_viewer      { is_expected.to match_array [participant, viewer, writer].map(&:role_id) }
        by_writer      { is_expected.to match_array [participant, viewer, writer].map(&:role_id) }
        by_admin       { is_expected.to match_array [participant, viewer, writer, admin].map(&:role_id) }
      end
    end
  end

  describe 'GET /api/members/:id' do
    let!(:viewer)      { create(:member, :viewer) }
    let!(:participant) { create(:member, :participant) }
    let!(:writer)      { create(:member, :writer) }
    let!(:admin)       { create(:member, :admin) }

    describe 'get viewer member' do
      let(:response) { get "/api/members/#{viewer.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_participant { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 200 }
      by_writer      { is_expected.to eq 200 }
      by_admin       { is_expected.to eq 200 }
    end

    describe 'get participant member' do
      let(:response) { get "/api/members/#{participant.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 200 }
      by_participant { is_expected.to eq 200 }
      by_writer      { is_expected.to eq 200 }
      by_admin       { is_expected.to eq 200 }
    end

    describe 'get writer member' do
      let(:response) { get "/api/members/#{writer.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_participant { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 200 }
      by_writer      { is_expected.to eq 200 }
      by_admin       { is_expected.to eq 200 }
    end

    describe 'get admin member' do
      let(:response) { get "/api/members/#{admin.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 404 }
      by_participant { is_expected.to eq 404 }
      by_writer      { is_expected.to eq 404 }
      by_admin       { is_expected.to eq 200 }
    end
  end

  describe 'POST /api/members' do
    let(:member) { build(:member, :participant) }
    let(:admin_role) { build(:role, :admin) }

    let(:params) do
      {
        name: member.name,
        login: member.login,
        password: member.password,
        team_id: member.team_id,
        registration_code: member.team.registration_code
      }
    end

    describe 'create participant member' do
      let(:response) { post '/api/members', params }
      subject { response.status }

      by_nologin do
        is_expected.to eq 201
        expect(json_response.keys).to match_array %w(id name login team_id created_at updated_at role_id)
        expect(json_response).not_to include('password')
        expect(json_response['role_id']).to eq member.role.id
      end

      by_viewer      { is_expected.to eq 403 }
      by_participant { is_expected.to eq 403 }

      all_success_block = Proc.new do
        is_expected.to eq 201
        expect(json_response.keys).to match_array %w(id name login team_id created_at updated_at role_id)
        expect(json_response['role_id']).to eq member.role.id
      end

      by_writer &all_success_block
      by_admin &all_success_block
    end

    describe 'create participant member with missing registration_code' do
      let(:params_without_registration_code) { params.except(:registration_code) }
      let(:response) { post '/api/members', params_without_registration_code }
      subject { response.status }

      by_nologin { is_expected.to eq 400 }
      by_writer  { is_expected.to eq 201 }
      by_admin   { is_expected.to eq 201 }
    end

    describe 'create admin member' do
      let(:params_with_admin_role_id) { params.merge(role_id: admin_role.id) }
      let(:response) { post '/api/members', params_with_admin_role_id }
      subject { response.status }

      by_nologin     { is_expected.to eq 403 }
      by_viewer      { is_expected.to eq 403 }
      by_participant { is_expected.to eq 403 }
      by_writer      { is_expected.to eq 403 }
      by_admin do
        is_expected.to eq 201
        expect(json_response.keys).to match_array %w(id name login team_id created_at updated_at role_id)
        expect(json_response['role_id']).to eq admin_role.id
      end
    end
  end

  describe 'PUT, PATCH /api/members' do
    let!(:other_roles) {
      create(:role, :viewer)
      create(:role, :participant)
      create(:role, :writer)
      create(:role, :admin)
    }

    describe "edit oneself login" do
      let!(:another_participant) { create(:member, :participant, team: create(:team)) }
      let(:new_login) { current_member.login + 'hoge' }
      let!(:new_role) { create(:role) }
      let(:new_team) { another_participant.team }

      let(:params) do
        {
          name: current_member.name,
          password: current_member.password,
          login: new_login,
          role_id: new_role.id,
          team_id: new_team.id
        }
      end

      shared_examples 'expected results' do
        subject { response.status }

        by_viewer { is_expected.to eq 404 }

        by_participant do
          is_expected.to eq 200
          expect(json_response['login']).to eq new_login
          expect(json_response['role_id']).to eq current_member.role_id
          expect(json_response['team_id']).to eq current_member.team_id
        end

        all_success_block = Proc.new do
          is_expected.to eq 200
          expect(json_response['login']).to eq new_login
          expect(json_response['role_id']).to eq new_role.id
          expect(json_response['team_id']).to eq new_team.id
        end

        by_writer &all_success_block
        by_admin &all_success_block
      end

      context 'PUT without some fields' do
        let(:response) { put "/api/members/#{current_member.id}", params.except(:name) }
        subject { response.status }

        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 400 }
        by_writer      { is_expected.to eq 400 }
        by_admin       { is_expected.to eq 400 }
      end

      context 'PATCH without some fields' do
        let(:response) { patch "/api/members/#{current_member.id}", params.except(:name) }
        it_behaves_like 'expected results'
      end

      context 'PUT' do
        let(:response) { put "/api/members/#{current_member.id}", params }
        it_behaves_like 'expected results'
      end
    end

    describe "edit other participant's login" do
      let(:other_a) { create(:member, :participant, team: create(:team)) }
      let(:other_b) { create(:member, :participant, team: create(:team)) }
      let(:new_login) { other_a.login + 'fuga' }
      let(:new_team) { other_b.team }
      let(:params) do
        {
          name: other_a.name,
          login: new_login,
          password: other_a.password + 'nyan',
          team_id: new_team.id,
          role_id: other_a.role_id
        }
      end

      shared_examples 'expected results' do
        subject { response.status }

        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }

        all_success_block = Proc.new do
          is_expected.to eq 200
          expect(json_response['login']).to eq new_login
          expect(json_response['hashed_password']).not_to eq other_a.hashed_password
          expect(json_response['team_id']).to eq new_team.id
        end

        by_writer &all_success_block
        by_admin &all_success_block
      end

      context 'PUT without some fields' do
        let(:response) { put "/api/members/#{other_a.id}", params.except(:name) }
        subject { response.status }

        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }
        by_writer      { is_expected.to eq 400 }
        by_admin       { is_expected.to eq 400 }
      end

      context 'PATCH without some fields' do
        let(:response) { patch "/api/members/#{other_a.id}", params.except(:name) }
        it_behaves_like 'expected results'
      end

      context 'PUT' do
        let(:response) { put "/api/members/#{other_a.id}", params }
        it_behaves_like 'expected results'
      end
    end

    describe "edit other writer's login" do
      let(:other) { create(:member, :writer) }
      let(:new_login) { other.login + 'fuga' }
      let(:params) do
        {
          name: other.name,
          login: new_login,
          password: other.password + 'nyan',
          team_id: nil,
          role_id: other.role_id
        }
      end

      shared_examples 'expected results' do
        subject { response.status }

        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }

        all_success_block = Proc.new do
          is_expected.to eq 200
          expect(json_response['login']).to eq new_login
          expect(json_response['hashed_password']).not_to eq other.hashed_password
        end

        by_writer &all_success_block
        by_admin &all_success_block
      end

      context 'PUT without some fields' do
        let(:response) { put "/api/members/#{other.id}", params.except(:name) }
        subject { response.status }

        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }
        by_writer      { is_expected.to eq 400 }
        by_admin       { is_expected.to eq 400 }
      end

      context 'PATCH without some fields' do
        let(:response) { patch "/api/members/#{other.id}", params.except(:name) }
        it_behaves_like 'expected results'
      end

      context 'PUT' do
        let(:response) { put "/api/members/#{other.id}", params }
        it_behaves_like 'expected results'
      end
    end

    describe "edit other admin's login" do
      let(:other) { create(:member, :admin) }
      let(:new_login) { other.login + 'fuga' }
      let(:params) do
        {
          name: other.name,
          login: new_login,
          password: other.password + 'nyan',
          role_id: other.role_id,
          team_id: nil
        }
      end

      shared_examples 'expected results' do
        subject { response.status }

        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }
        by_writer      { is_expected.to eq 404 }

        all_success_block = Proc.new do
          is_expected.to eq 200
          expect(json_response['login']).to eq new_login
          expect(json_response['hashed_password']).not_to eq other.hashed_password
        end

        by_admin &all_success_block
      end

      context 'PUT without some fields' do
        let(:response) { put "/api/members/#{other.id}", params.except(:name) }
        subject { response.status }

        by_viewer      { is_expected.to eq 404 }
        by_participant { is_expected.to eq 404 }
        by_writer      { is_expected.to eq 404 }
        by_admin       { is_expected.to eq 400 }
      end

      context 'PATCH without some fields' do
        let(:response) { patch "/api/members/#{other.id}", params.except(:name) }
        it_behaves_like 'expected results'
      end

      context 'PUT' do
        let(:response) { put "/api/members/#{other.id}", params }
        it_behaves_like 'expected results'
      end
    end
  end

  describe 'DELETE /api/members/:id' do
    let!(:viewer)      { create(:member, :viewer) }
    let!(:participant) { create(:member, :participant) }
    let!(:writer)      { create(:member, :writer) }
    let!(:admin)       { create(:member, :admin) }

    describe 'delete viewer member' do
      let(:response) { delete "/api/members/#{viewer.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 404 }
      by_participant { is_expected.to eq 404 }
      by_writer      { is_expected.to eq 204 }
      by_admin       { is_expected.to eq 204 }
    end

    describe 'delete participant member' do
      let(:response) { delete "/api/members/#{participant.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 404 }
      by_participant { is_expected.to eq 404 }
      by_writer      { is_expected.to eq 204 }
      by_admin       { is_expected.to eq 204 }
    end

    describe 'delete writer member' do
      let(:response) { delete "/api/members/#{writer.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 404 }
      by_participant { is_expected.to eq 404 }
      by_writer      { is_expected.to eq 204 }
      by_admin       { is_expected.to eq 204 }
    end

    describe 'delete admin member' do
      let(:response) { delete "/api/members/#{admin.id}" }
      subject { response.status }

      by_nologin     { is_expected.to eq 404 }
      by_viewer      { is_expected.to eq 404 }
      by_participant { is_expected.to eq 404 }
      by_writer      { is_expected.to eq 404 }
      by_admin       { is_expected.to eq 204 }
    end
  end
end
