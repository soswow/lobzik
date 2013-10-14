This is simple application that you can use for test person's knowledge of something.
Currently it is more specific for testing Front-end developer, because it can check JavaScript coding abilities.


Example of production instance is available here: [test.toggl.com](test.toggl.com)

###Features
* Multiple answer test questions
* Free text answers (cloze)
* Code assignment with automatic tests running on client side
* Creative code assignment where user can solve some problem in order to show his creativity
* Ability to write code in JavaScript or CoffeeScript
* User get randomly picked questions from a larger pool of questions
* Login with Github or LinkedIn
* Campfire notification when user finishes the test

![Login screen](/images/Screenshot1.png "Login screen")
![Test assignment](/images/Screenshot2.png "Test assignment")
![Code assignment](/images/Screenshot3.png "Code assignment")

###How to run
This project uses grunt for building and running development version.
Just run `grunt` to run local dev version. Application uses mongodb, so in order to run it should be available.

###How to build
To build project run `grunt build` and you will get ready to deploy client code in folder `/dist`