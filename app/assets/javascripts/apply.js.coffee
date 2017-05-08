$ ->
  check_to_hide_add_link = ->
    #max_users = parseInt($("#asset_max_users").val(), 10)
    if $("#letters .nested-fields").length >= $("#student_application_max_letters").val()
      $("#letters .links a").hide()
    else
      $("#letters .links a").show()

  $("#letters").bind "cocoon:after-insert", ->
    check_to_hide_add_link()

  $("#letters").bind "cocoon:after-remove", ->
    check_to_hide_add_link()

  check_to_hide_add_link()
