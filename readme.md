This is simple application that you can use for test person's knowledge of something.
Currently it is more specific for testing Front-end developer, because it can check JavaScript coding abilities.


Example of production instance is available here: [test.toggl.com](https://test.toggl.com)

###Features
* Multiple answer test questions
* Free text answers (cloze)
* Code assignment with automatic tests running on client side
* Creative code assignment where user can solve some problem in order to show his creativity
* Ability to write code in JavaScript or CoffeeScript
* User get randomly picked questions from a larger pool of questions
* Login with Github or LinkedIn
* Campfire notification when user finishes the test

####Login screen
![Login screen](/images/Screenshot1.png "Login screen")
####Test question screen
![Test assignment](/images/Screenshot2.png "Test assignment")
####Code assignment screen
![Code assignment](/images/Screenshot3.png "Code assignment")

###How to run
This project uses grunt for building and running development version.
* First make sure you have mongodb running.
* You need to rename `server/_config.coffee` to `server/config.coffee` and fill it with right information
* Also you need `compass` for scss processing.

Finally run `grunt` to make it start in development mode.

###How to build
To build project run `grunt build` and you will get ready to deploy client code in folder `/dist`. In order to start server-side separatly you need to: 
* Run compile npm modules in with `production` flag `npm install --production`
* Put `npm-modules` folder and other files from `/server` folder together. Resultig folder will look like
```
./
../
config.coffee
node_modules/
quiz-config.js
server.coffee
```
* Run server with `server.coffee`
