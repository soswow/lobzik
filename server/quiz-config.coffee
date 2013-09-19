module.exports =
  maxDuration: 5000000
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
      testCase: (fun, assert) ->
          answers = [0,1,2,'foo',4,'bar','foo',7,8,'foo','bar',11,'foo',13,14,'foobar']
          for ans, i in answers
            assert fun(i), ans
    }
    {
      name: "harder"
      description: "Implement a function that reverse a input string"
      placeholderCode: "(line) -> #your code goes here"
      testCase: (fun, assert) ->
        assert fun(''), ''
        assert fun('a'), 'a'
        assert fun('ab'), 'ba'
        assert fun('abc'), 'cba'
        assert fun('abcd'), 'dcba'
    }
  ]
  creativeCodeAssignment:
    name: "creative"
    description: "Wanna prove you are The Best? Prove it! Draw us a fireworks! Make it awesome! (Canvas 2d context object is given as argument)"
    placeholderCode: "(ctx) -> #your code goes here"