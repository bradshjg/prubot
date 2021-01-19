# Prubot

Prubot is a Ruby Probot (https://github.com/probot/probot) clone. Probot is a framework for building GitHub Apps to
automate and improve your workflow.

GitHub has a [good comparions of GitHub Actions to GitHub Apps](https://docs.github.com/en/actions/creating-actions/about-actions#comparing-github-actions-to-github-apps).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prubot'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install prubot

## Usage

Here is an example of an Welcome Mat:tm: app that comments on opened issues inviting users to join in on discussions:

Make sure you [enable discussions] on any repos you add to this App.

`welcomemat.rb`
```ruby
require 'prubot'


on 'issues.opened' do
    # `payload` is a hash of the event payload.
    discussions_link = payload??? # FIXME
    welcome_message = "Thanks for stopping by :wave:. While we work on getting back to you please feel free to check out #{discussions_link}" FIXME

    # `issue` extracts information from the event, which can be passed to
    # GitHub API calls (equivalent `pull_request` exists as well). This will return:
    #   { owner: 'yourname', repo: 'yourrepo', number: 123, body: 'Thanks for stopping by...'}
    params = issue({ body: welcome_message });

    # `octokit` provides a hydrated (authenticated as the App installation) octokit.rb client
    # for interacting with GitHub.
    octokit.add_comment(params);
done
```

To run the Welcome Mat

`ruby welcomemat.rb`

You should see a link to create a GitHub App.

`Welcome to Prubot! Please visit http://localhost:3000 to get started.`

Follow that link, and once you've completed the registration you'll be redirected to install the app on repositories.
Choose a test repository and then try opening a new issue in that repository!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bradshjg/prubot. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/bradshjg/prubot/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Prubot project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bradshjg/prubot/blob/master/CODE_OF_CONDUCT.md).
