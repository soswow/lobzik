module.exports =
  maxDuration: 1000 * 60 * 100
  testQuestionsToShow: 4
  codeAssignmentsToShow: 3
  testQuestions: [
    {
      name: "q-1"
      description: "Did you catch that fish?"
      options: [
        "No I talked him into giving himself up."
        "No I was sitting here minding my own business when the crazy thing jumped into my pail."
        "No it's a plastic model to get people like you to start fascinating conversations."
      ]
      rightAnswers: [2, 1]
    }
    {
      name: "question-two"
      description: "Question two"
      options: [
        "wrong answer 1"
        "wrong answer 2"
        "right answer"
      ]
      rightAnswers: [2]
    }
    {
      name: "question-three"
      description: "Question three"
      options: [
        "wrong answer 1"
        "wrong answer 2"
        "right answer"
      ]
      rightAnswers: [0, 2]
    }
    {
      name: "iterator-question"
      description: """
                   Look at the given CSS. We view the pages two different ways.
                   <ul>
                    <li>In a browser window with width of 720px, and height of 1000px;</li>
                    <li>In a Retina display iPhone (resolution [640 × 960])</li>
                  </ul>

                   What is the height and padding of the header element in both cases?
                   What is the font-size of the h2 element in both cases?

                   <pre class="brush: scss; tab-size: 2; smart-tabs: false">
header {
  background: #2a3d4b;
  padding: 10px;
  overflow: hidden;
  height: 45px;
}
.main-list{
  margin:0;
  width:auto;
}
.main-list > li {
  margin: 0 10px;
}
h2{
  font-size:12px;
}
@media only screen and (max-width: 800px) {
  ul.main-list{
    margin:0 -10px;
  }
  .main-list > li {
    margin: 0 10px;
  }
  header {
    padding: 8px;
    height: 50px;
  }
}
@media screen and (min-height: 350px) {
  header {
    height: 55px;
  }
}
@media only screen and (-webkit-min-device-pixel-ratio: 2) {
  h2{
    font-size:14px;
  }
  header {
    height: 60px;
  }
}
</pre>"""
      cloze: "<div class='cloze-line'>header height in browser is {0} px</div><div class='cloze-line'>h2 font-size in iPhone is {1} px</div>"
      rightAnswers: ['55', '14']
    }
  ]
  codeAssignments: [
    {
      name: "hello-world"
      description: "Gimme 'Hello World'"
      placeholderCode:
        coffeescript: " -> #your code goes here"
        javascript: "function(){\n\t//your code goes here\n}"
      testCase: ->
        @assert null, "Hello World"
    }
    {
      name: "foobar-game"
      description: "Let's play `foo-bar` game! Implement function that returns `foo` if given input divisible by 3 `bar` if divisible by 5 and `foobar` if divisible by 3 AND 5 otherwise return number itself."
      placeholderCode:
        coffeescript: "(num) -> #your code goes here"
        javascript: "function(num){\n\t//your code goes here\n}"
      testCase: ->
          answers = ['foobar', 1, 2,'foo',4,'bar','foo',7,8,'foo','bar',11,'foo',13,14,'foobar']
          for ans, i in answers
            @assert [i], ans
    }
    {
      name: "harder"
      description: "Implement a function that reverse a input string"
      placeholderCode:
        coffeescript: "(line) -> #your code goes here"
        javascript: "function(line){\n\t//your code goes here\n}"
      testCase: ->
        @assert [''],  ''
        @assert ['a'], 'a'
        @assert ['ab'], 'ba'
        @assert ['abc'], 'cba'
        @assert ['abcd'], 'dcba'
    }
  ]
  creativeCodeAssignment:
    name: "creative"
    description: """
                 Wanna prove you are The Best? </br>
                 Prove it! Draw us a fireworks! Make it awesome!
                 <canvas id='awesome-canvas' height='300' width='480'></canvas>
                 """
    placeholderCode:
      coffeescript: """
                     canvas = document.getElementById 'awesome-canvas'
                     console.log canvas
                     ctx = canvas.getContext '2d'
                     #your code goes here and bellow
                     ctx.moveTo 0, 0
                     ctx.lineTo 100,100
                     ctx.stroke()
                     """
      javascript: """
                       var canvas = document.getElementById('awesome-canvas')
                       console.log(canvas)
                       var ctx = canvas.getContext('2d')
                       //your code goes here and bellow
                       ctx.moveTo(0, 0)
                       ctx.lineTo(100,100)
                       ctx.stroke()
                       """