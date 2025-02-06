# frozen_string_literal: true
# name: discourse-search-extensions
# about: An extension to search to allow you to search messages for involved users as well as those that have posted
# version: 0.0.1
# authors: Robert Barrow
# url: https://github.com/merefield/discourse-search-extensions

enabled_site_setting :search_extensions_enabled

module ::SearchExtensions
  PLUGIN_NAME = "search-extensions".freeze
end

require_relative "lib/search_extensions/engine"

after_initialize do
  reloadable_patch do
    # Because we are adding a new filter, we need to use class_eval as it's not a method that can be overridden
    # rubocop:disable Discourse/Plugins/NoMonkeyPatching
    Search.class_eval do
      advanced_filter(/\A\~(\S+)\z/i) do |posts, match|
        username = User.normalize_username(match)

        user_id = User.not_staged.where(username_lower: username).pick(:id)

        user_id = @guardian.user&.id if !user_id && username == "me"

        if user_id
          posts.where("posts.user_id = ? OR posts.topic_id IN (SELECT topic_id FROM topic_users WHERE user_id = ?)", user_id, user_id)
        else
          posts.where("1 = 0")
        end
      end
    end
    # rubocop:enable Discourse/Plugins/NoMonkeyPatching
  end
end
