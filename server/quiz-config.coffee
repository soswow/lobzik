module.exports =
  maxDuration: 1000 * 60 * 100
  testQuestionsToShow: 2
  codeAssignmentsToShow: 2
  testQuestions: [
    {
      name: "q-1"
      description: "Did you catch that fish?"
      options: [
        "No I talked him into giving himself up."
        "No I was sitting here minding my own business when the crazy thing jumped into my pail."
        "No it's a plastic model to get people like you to start fascinating conversations."
      ]
      rightAnswer: 2
    }
    {
      name: "question-two"
      description: "Question two"
      options: [
        "wrong answer 1"
        "wrong answer 2"
        "right answer"
      ]
      rightAnswer: 2
    }
    {
      name: "question-three"
      description: "Question three"
      options: [
        "wrong answer 1"
        "wrong answer 2"
        "right answer"
      ]
      rightAnswer: 2
    }
  ]
  codeAssignments: [
    {
      name: "foobar-game"
      description: "Let's play `foo-bar` game! Implement function that returns `foo` if given input divisible by 3 `bar` if divisible by 5 and `foobar` if divisible by 3 AND 5 otherwise return number itself."
      placeholderCode: "(num) -> #your code goes here"
      testCase: ->
          answers = ['foobar', 1, 2,'foo',4,'bar','foo',7,8,'foo','bar',11,'foo',13,14,'foobar']
          for ans, i in answers
            @assert [i], ans
    }
    {
      name: "harder"
      description: "Implement a function that reverse a input string"
      placeholderCode: "(line) -> #your code goes here"
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
    placeholderCode: """
                     canvas = document.getElementById 'awesome-canvas'
                     console.log canvas
                     ctx = canvas.getContext '2d'
                     #your code goes here and bellow
                     ctx.moveTo 0, 0
                     ctx.lineTo 100,100
                     ctx.stroke()
                     """