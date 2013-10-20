module.exports =
  mongoUrl: 'mongodb://localhost/test'
  sessionKey: 'blahbahblah' #Some random unique string
  campfire: # You can comment this section if you don't want this.
    account: 'company-name' #As in company-name.campfirenow.com
    roomId: 83782
    apiToken: 'token'
  github:
    appId: '1234'
    appSecret: '5678'
  linkedIn:
    consumerKey: '09101112'
    consumerSecret: '131415'
    state: 'blahblah' #A long unique string value of your choice that is hard to guess. Used to prevent CSRF.
  admins: ['admin@company.com']