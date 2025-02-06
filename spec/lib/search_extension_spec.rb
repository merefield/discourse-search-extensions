# frozen_string_literal: true

RSpec.describe Search do
  fab!(:admin) { Fabricate(:admin, refresh_auto_groups: true) }
  fab!(:topic)

  before do
    SearchIndexer.enable
    Jobs.run_immediately!
  end

  # describe "searching involved" do
  context "searching involved" do
    let!(:current) do
      Fabricate(:user, admin: true, username: "current_user", refresh_auto_groups: true)
    end
    let!(:participant) { Fabricate(:user, username: "participant_1", refresh_auto_groups: true) }
    let!(:participant_2) do
      Fabricate(:user, username: "participant_2", refresh_auto_groups: true)
    end
    let!(:participant_3) do
      Fabricate(:user, username: "participant_3", refresh_auto_groups: true)
    end

    def create_pm(users:, group: nil)
      pm = Fabricate(:private_message_post_one_user, user: users.first).topic
      users[1..-1].each do |u|
        pm.invite(users.first, u.username)
        Fabricate(:post, user: u, topic: pm, raw: "help me with my maths problem please")
      end
      pm.reload
    end

    def create_unreplied_pm(users:, group: nil)
      pm = Fabricate(:private_message_post_one_user, user: users.first, raw: "help me with my maths problem please").topic
      users[1..-1].each do |u|
        pm.invite(users.first, u.username)
      end
      pm.reload
    end

    it "can filter direct PMs by @username" do
      pm = create_pm(users: [current, participant]) # not the right person
      pm_2 = create_pm(users: [participant_2, current]) # involved and posted
      pm_3 = create_unreplied_pm(users: [participant_2, current]) # involved but not posted
      pm_4 = create_pm(users: [participant_3, current]) # not involved
      [
        "~#{participant_2.username} help in:messages"
      ].each do |query|
        results = Search.execute(query, guardian: Guardian.new(current))
        expect(results.posts.size).to eq(2)
        expect(results.posts.map(&:topic_id)).to contain_exactly(pm_2.id, pm_3.id)
      end
    end
  end
end
