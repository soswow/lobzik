module.exports =
  maxDuration: 1000 * 60 * 42
  testQuestionsToShow: 4
  codeAssignmentsToShow: 3
  testQuestions: [
    {
      name: "question-one"
      description: "Question one"
      options: [
        "wrong answer 1"
        "right answer 1"
        "right answer 2"
      ]
      rightAnswers: [2, 1]
    }
    {
      name: "question-two"
      description: "Question two"
      options: [
        "wrong answer 1"
        "wrong answer 2"
        "right answer 1"
      ]
      rightAnswers: [2]
    }
    {
      name: "question-three"
      description: "Question three"
      options: [
        "right answer 1"
        "wrong answer 1"
        "right answer 2"
      ]
      rightAnswers: [0, 2]
    }
    {
      name: "iterator-question"
      description: """
                   What is the hight and width of the box?
                   <pre class="brush: scss; tab-size: 2; smart-tabs: false">
.box {
  height: 10px;
  width: 20px;
}
</pre>"""
      cloze: "<div class='cloze-line'>box height is {0} px</div><div class='cloze-line'>box's width is {1} px</div>"
      rightAnswers: ['10', '20']
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
          foobarNumber = Math.round((Math.random() * 1000)) * 15
          try
            @assert [foobarNumber], 'foobar'
          catch e
            throw "Until 15 it works, but than it doesn't. Hacker?"
    }
    {
      name: "harder"
      description: """
                   Implement a function that reverse a input string.<br/>
                   <span class='tip-text'>(Bonus points for not using for/while loops or Array.reverse)</span>
                   """
      placeholderCode:
        coffeescript: "(line) -> #your code goes here"
        javascript: "function(line){\n\t//your code goes here\n}"
      testCase: ->
        @assert [''],  ''
        @assert ['a'], 'a'
        @assert ['ab'], 'ba'
        @assert ['abc'], 'cba'
        @assert ['abcd'], 'dcba'
        randomString = (Math.round(Math.random()) for n in [0..20]).join("")
        @assert [randomString], randomString.split("").reverse().join("")
    }
  ]
  creativeCodeAssignment:
    name: "creative"
    description: """
                 Wanna prove you are The Best? </br>
                 Prove it! Draw us a fireworks! Make it awesome!
                 <canvas id='awesome-canvas' height='300' width='480'></canvas>
                 <div class='canvas-controls'>
                 <button id='startLife' class='btn btn-success'>Start</button>
                 <button id='killLife' class='btn btn-danger'>Reset</button>
                 </div>
                 <span class='tip-text'>
                 (Don't forget to press 'Test and save...' to eval() your code before starting game)
                 </span>
                 """
    placeholderCode:
      coffeescript: """
                      canvas = document.getElementById 'awesome-canvas'
                      ctx = canvas.getContext '2d'

                      reset = -> canvas.width = canvas.width
                      reset()
                      $("#startLife").click ->
                        reset()
                        # Your code probobly goes here, like this
                        ctx.moveTo 0, 0
                        ctx.lineTo 100,100
                        ctx.stroke()

                      $("#killLife").click -> reset()
                     """
      javascript: """
                  function(){
                    var canvas = document.getElementById('awesome-canvas');
                    var ctx = canvas.getContext('2d');

                    var reset = function(){ canvas.width = canvas.width; }
                    reset();
                    $("#startLife").click(function(){
                      reset();
                      // Your code probobly goes here, like this
                      ctx.moveTo(0, 0);
                      ctx.lineTo(100,100);
                      ctx.stroke();
                    });

                    $("#killLife").click(function(){ reset(); });
                  }()
                       """