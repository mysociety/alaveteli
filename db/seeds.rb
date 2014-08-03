# Users

admin_user = User.create(name: 'James George Jameson',
                         email: 'admin@example.org',
                         password: 'admin',
                         address: 'Law Street',
                         admin_level: 'super',
                         email_confirmed: true)

test_user = User.create(name: 'Alan Joe Parker',
                        email: 'test@example.org',
                        password: 'test',
                        address: 'Law Street',
                        admin_level: 'none',
                        email_confirmed: true)

# Public bodies

authority = PublicBody.create(name: 'Authority',
                              short_name: 'AUTH',
                              request_email: 'authorithy@example.org',
                              last_edit_comment: 'Initialised',
                              last_edit_editor: 'somebody')

ministry_of_madness = PublicBody.create(name: 'Ministry of Madness',
                                        short_name: 'MoM',
                                        request_email: 'mom@example.org',
                                        last_edit_comment: 'Initialised',
                                        last_edit_editor: 'somebody')

# Info requests

stupid_request = InfoRequest.create(title: 'Hey, sup?',
                                    public_body: authority,
                                    user: test_user,
                                    prominence: 'normal',
                                    address: 'Law Street')

stupid_request_initial_message = OutgoingMessage.create(status: 'sent',
                                                        message_type: 'initial_request',
                                                        what_doing: 'normal_sort',
                                                        info_request: stupid_request,
                                                        last_sent_at: Time.now(),
                                                        body: 'Hey guys, wassup??',
                                                        address: 'Law Street')

stupid_request_event = InfoRequestEvent.create(event_type: 'sent',
                                               params: {},
                                               info_request: stupid_request,
                                               outgoing_message: stupid_request_initial_message)


formal_request = InfoRequest.create(title: 'I would like to make an information request',
                                    public_body: ministry_of_madness,
                                    user: test_user,
                                    prominence: 'normal',
                                    address: 'Law Street')

formal_request_initial_message = OutgoingMessage.create(status: 'sent',
                                                        message_type: 'initial_request',
                                                        what_doing: 'normal_sort',
                                                        info_request: formal_request,
                                                        last_sent_at: Time.now(),
                                                        body: 'I am not sure what I really want to know...',
                                                        address: 'Law Street')


formal_request_outgoing_event = InfoRequestEvent.create(event_type: 'sent',
                                                        params: {},
                                                        info_request: formal_request,
                                                        outgoing_message: formal_request_initial_message)

mail = RequestMailer.external_response(formal_request, 'I really cannot answer that...', Time.now(), {})
formal_request.receive(mail, mail.encoded, true)
