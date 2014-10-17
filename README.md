# RadBus Web API

[ ![Codeship Status for RadBus/api](https://www.codeship.io/projects/1f8c7e60-c700-0131-5428-0277a4446f20/status)](https://www.codeship.io/projects/22112)
[ ![Dependency Status](https://david-dm.org/RadBus/api/status.svg?theme=shields.io)](https://david-dm.org/RadBus/api)

You've found the source code for the RadBus Web API!

To learn more about RadBus, check out: http://dev.radbus.io

## Development Environment

In order to contribute or at least play with the code and see how RadBus works under the hood, you need to set up your own development environment.

**NOTES**: 
* These instructions assume you already have a GitHub account and have Git [set up on your local machine](https://help.github.com/articles/set-up-git).
* These instructions are for Mac OS.  There's no reason why RadBus wouldn't run on Linux or Windows since it's just a Node.js app.  We can create instructions for other OS's as needed down the road.

Here are the steps:

1. If you haven't already, install [Node.js](http://nodejs.org/download/)

1. If you haven't already, sign up for a free [Heroku account](https://id.heroku.com/signup) and install the [Heroku Toolbelt](https://toolbelt.heroku.com/)  
  
  **NOTE**: Technically Heroku is not required to run RadBus locally.  However, it makes setting up your dev environment a lot easier.  Plus if you'd like to push your version of RadBus to the cloud (for free), you've got an easy option.  It's also the hosting environment for the [production RadBus API](https://api.radbus.io)!

1. [Fork this repo](https://github.com/RadBus/api/fork) and clone it down to your local machine:  

  ```bash
  $ git clone git@github.com:<your-git-username>/radbus-api.git
  ```

1. Install Node.js dependencies:

  ```bash
  $ npm install
  ```

1. Capture the environment variables used by RadBus in a local `.env` file, which will be read by `foreman`, the tool we'll use to run the app locally:

   ```bash
   echo 'RADBUS_FUTURE_MINUTES=60' >> .env
   echo 'RADBUS_TIMEZONE=America/Chicago' >> .env

   # get the following values from the JSON returned by https://api.radbus.io/v1/oauth2
   echo 'RADBUS_GOOGLE_API_AUTH_SCOPES=value' >> .env
   echo 'RADBUS_GOOGLE_API_CLIENT_ID=value' >> .env
   echo 'RADBUS_GOOGLE_API_CLIENT_SECRET=value' >> .env

   # the salt value can be anything you want it to be
   echo 'RADBUS_USER_ID_SALT=use-the-force' >> .env

   # enable/disable API Keys
   echo 'API_KEYS_ENABLED=true' >> .env

   # comma-separated list of API keys. These can be anything you want it to be
   # If API_KEYS is enabled, all API requests must contain one of these keys
   echo 'API_KEYS=rad,bus,1234' >> .env
   ```

1. Create a MongoDB database used by the API to store user schedules.  This is where Heroku helps a ton.  While you could install and run MongoDB locally or go out and fire up a free cloud-based instance somewhere, the following steps in Heroku will set it up in minutes using MongoHQ, one of their add-on partners:

  1. If you haven't done so already, log into Heroku:

     ```bash
     $ heroku login
     ```

     **NOTE**: If Heroku reports that you don't have an existing public key and asks if you'd like to create one, answer yes!

  1. Create a new Heroku app:

     ```bash
     $ heroku create
     ```

     You'll see output that looks something like this:

     ```
     Creating warm-sierra-1964... done, stack is cedar
     http://warm-sierra-1964.herokuapp.com/ | git@heroku.com:warm-sierra-1964.git
     Git remote heroku added
     ```

     If that was the output of your app, your app's URL would be:

     ```
     http://warm-sierra-1964.herokuapp.com/
     ```

     **NOTE**: You won't have to deploy your code to this app if you don't want to.  However, we're going to the add-ons that we register with it to power your local dev environment.

  1. Add the free MongoHQ database "Sandbox" add-on:

     ```bash
     $ heroku addons:add mongohq 
     ```

  1. Get the value of the `MONGOHQ_URL` environment variable of the MongoDB database created by that add-on:

     ```bash
     $ heroku config
     ```

  1. Capture that in our `.env` file:

     ```bash
     # value is from the heroku config command output
     echo 'MONGOHQ_URL=value' >> .env
     ```

1. Try running all the tests to make sure they pass on your machine:

  ```bash
  $ npm test
  ```

1. Start the local app:

  ```bash
  $ foreman start
  ```

  **NOTE**: By default `foreman` runs on port 5000.

1. In a different Terminal window, try hitting the [version 1 Root resource](http://dev.radbus.io/#root-resource):

  ```bash
  $ curl http://localhost:5000/v1 | python -m json.tool
  ```

  You should get output that looks something like this:

  ```
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  100    77  100    77    0     0  24421      0 --:--:-- --:--:-- --:--:-- 25666
  {
      "api_version": "1.0.0",
      "app_version": "0.3.2",
      "service_name": "RadBus Web API"
  }
  ```

That's it!  

## Option: Push to Heroku

If you make some changes, commit them to your local repo, and would like to push them up to your Heroku account for all to see, all you have to do is:

```bash
$ git push heroku master
```

If you browse to the base URL of your app, you will get automatically redirected (302) to the [REST API Documentation](http://dev.radbus.io) site.  Try hitting one of the other resources instead.  For example:

```bash
$ curl https://warm-sierra-1964.herokuapp.com/v1 | python -m json.tool
```

**NOTE**: The RadBus API requires SSL unless running on `localhost`.  Be sure to use `https://` URL's with your REST clients to avoid getting a 301 response.

## Generating an OAuth2 Token

Per the [REST Documentation](http://dev.radbus.io/#authentication) in order to access many of the API's resources, you need to pass an OAuth2 token so it can identify you and look up your schedule.  Having a valid token on hand is often necessary when developing, but it can be a little tricky.  This section exists to provide some easy techniques to do so.

### Method 1: Use a token from a website session

The easiest method to obtain an actual valid token is using the RadBus website since it will be *your* user token and will have an actual schedule associated with it (assuming you've already set one up).  Here's how:

1. Open a new window in your web browser.  In this example we will be using the [Google Chrome](https://www.google.com/chrome/browser/) browser, but any browser will do as long as you know how to view it's HTTP traffic.
1. Open **Developer Tools** (Menu > *Tools* > *Developers Tools*).
1. Click on the **Network** tab.
1. Browse to the [RadBus website](https://www.radbus.io).
1. Several network calls should show up in the **Developer Tools** pane.  You're looking for one close to the bottom of the list that represents an AJAX `GET` call to either the [Schedule resource](http://dev.radbus.io/#fetch-get-v1schedule) or the [Departures resource](http://dev.radbus.io/#fetch-get-v1departures) since both of those require authentication.  For example a call to Schedule will have the following attributes:  

  Name/Path | Method | Status/Text | Type | Initiator
  ---|---|---|---|---
  `schedule` / `api.radbus.io/v1` | `GET` | `200` / `OK` | `application\json` | `Other`

1. Select that call and then make sure the **Headers** tab is selected.
1. Under the *Request Headers* section you should see a header called `Authorization`.  Select and copy its entire value, including the prefixing `Bearer `.

You now have a valid token!  However, this one will only last for an hour, so as you're developing it may expire and you'll have to perform the above process again to get a new one.

# Using API Keys

If you are running your own radbus-api server and have the API_KEYS_ENABLED flag enabled:

```bash
API_KEYS_ENABLED=true
API_KEYS=rad,bus,1234
```

You will need to include an api-key header in all api requests.
Here is an example using curl:

```bash
$ curl --header "api-key: 1234" http://localhost:5001/v1/routes
```

Note that for authorized requests you will also need to include the OAuth token provided from the OAuth2 provider. Here is an example of an authorized request with the API_KEYS_ENABLED flag enabled:
```bash
$ curl -H "api-key: 1234" -H "Authorization: Bearer AbCdEf123456" http://localhost:5001/v1/departures
```
