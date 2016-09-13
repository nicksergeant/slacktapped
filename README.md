# Slacktapped

Slacktapped is an <a href="http://elixir-lang.org/">Elixir</a> app to post
<a href="https://untappd.com/">Untappd</a> activity to
<a href="https://slack.com/">Slack</a>.

Once installed, this bot will post checkins, badges, and comments to a Slack
channel.

## Setup

1. Apply for an <a href="https://untappd.com/api/">Untappd API application</a>.
   Make sure you set a Callback URL for the application (any valid URL).
2. Create an <a href="https://api.slack.com/incoming-webhooks">incoming webhook</a>
   and point it to the channel of your choosing in your Slack team.
3. Create a new Untappd user. This user will be a standalone user that the bot
   will authenticate as.
4. For any people whose Untappd activity you want this bot to post, have that
   person "friend" the Untappd user created in step 3, and then accept the
   friendship on Untappd.
5. <a href="https://redislabs.com/redis-cloud">Obtain</a> or deploy a Redis
   instance. Redis is used to keep track of activity that has been posted to
   Slack.
6. With your Untappd API credentials, authenticate as your user using the
   <a href="https://untappd.com/api/docs#authentication">"Client Side Authentication" instructions here</a>.
   Use the provided Callback URL you specified in step 1. Make note of the
   returned `access_token` in the URL. Currently Untappd does not expire access
   tokens retrieved in this manner, but we may implement proper OAuth support
   for Slacktapped in the future.
7. Clone this repo and deploy to <a href="https://www.heroku.com/">Heroku</a>
   or <a href="http://dokku.viewdocs.io/dokku/">Dokku</a>, by following the
   instructions below. You should also be able to deploy to any system that
   supports building applications via <a href="https://devcenter.heroku.com/articles/buildpacks">buildpacks</a>.

## Deployment

1. Do a `git push` to Heroku or your Dokku server.
2. Set your environment variables:

```
INSTANCE_NAME=''         # Unique name for this Slacktapped instance.
REDIS_HOST=''            # Hostname for your Redis isntance.
SLACK_WEBHOOK_URL=''     # Your Slack incoming webhook URL.
UNTAPPD_ACCESS_TOKEN=''  # Token obtained via auth request above.
UNTAPPD_CLIENT_ID=''     # Your Untappd client ID.
UNTAPPD_CLIENT_SECRET='' # Your Untappd client secret.
```

Once you've deployed with the proper credentials, you should start seeing logs
for your application indicating that the processor is running. It will poll
Untappd every 60 seconds for new activity:

```
[Processor] Running...
[Processor] Done.
```

With any luck, you'll see Untappd activity in your Slack channel:

![http://i.nick.sg/45afb435b99b478eb4dade42567072af.png](http://i.nick.sg/45afb435b99b478eb4dade42567072af.png)

## Support

If you need help deploying or have an idea for a feature,
<a href="https://github.com/nicksergeant/slacktapped/issues/new">create an issue</a>.
