# frozen_string_literal: true

require 'prubot'

on 'issues', 'opened', 'add a welcome message' do
  # `payload` is a hash of the event payload.
  discussions_link = payload['repository']['discussions_url']
  welcome_message = 'Thanks for stopping by :wave:. While we work on getting back to you '\
  "please feel free to check out #{discussions_link}."

  # `issue` extracts information from the event, which can be passed to
  # GitHub API calls (equivalent `pull_request` exists as well). This will return:
  #   { owner: 'yourname', repo: 'yourrepo', number: 123, body: 'Thanks for stopping by...'}
  params = issue({ body: welcome_message })

  # `octokit` provides a hydrated (authenticated as the App installation) octokit.rb client
  # for interacting with GitHub.
  octokit.add_comment(params)
end
