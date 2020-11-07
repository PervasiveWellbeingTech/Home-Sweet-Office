######### Libraries

hso_server_url = 'http://green-antonym-197023.wl.r.appspot.com'
stress_level_before = 0
stress_change = 0

{polymer_ext} = require 'libs_frontend/polymer_utils'

{load_css_file} = require 'libs_common/content_script_utils'
{add_log_feedback, add_log_interventions, add_log_habitlab_disabled, add_log_habitlab_enabled} = require 'libs_backend/log_utils'

swal_cached = null
get_swal = ->>
  if swal_cached?
    return swal_cached
  swal_cached := await SystemJS.import('sweetalert2')
  return swal_cached

screenshot_utils_cached = null
get_screenshot_utils = ->>
  if screenshot_utils_cached?
    return screenshot_utils_cached
  screenshot_utils_cached := await SystemJS.import('libs_common/screenshot_utils')
  return screenshot_utils_cached

{
  get_active_tab_url
  get_active_tab_id
  list_currently_loaded_interventions
  list_currently_loaded_interventions_for_tabid
  get_active_tab_info
  disable_interventions_in_active_tab
  open_debug_page_for_tab_id
} = require 'libs_backend/background_common'

{
  open_debug_page_for_tab_id
} = require 'libs_backend/debug_console_utils'

{
  url_to_domain
} = require 'libs_common/domain_utils'

{
  set_intervention_disabled
  list_enabled_interventions_for_location
  set_intervention_disabled_permanently
  get_enabled_interventions
  set_intervention_enabled
  get_nonpositive_goals_and_interventions
  list_available_interventions_for_location
  get_interventions
  is_it_outside_work_hours
} = require 'libs_backend/intervention_utils'

{
  get_seconds_spent_on_all_domains_today        # map for all domains
} = require 'libs_common/time_spent_utils'

{
  is_habitlab_enabled
  disable_habitlab
  enable_habitlab
} = require 'libs_common/disable_habitlab_utils'

{
  list_sites_for_which_goals_are_enabled
  list_goals_for_site
  set_goal_enabled
  set_goal_disabled
  add_enable_custom_goal_reduce_time_on_domain
} = require 'libs_backend/goal_utils'

{
  localstorage_getjson
  localstorage_setjson
  localstorage_getbool
  localstorage_setbool
  localstorage_setstring
  localstorage_getstring
} = require 'libs_common/localstorage_utils'

{
  post_json
  get_json
} = require 'libs_backend/ajax_utils'

{
  get_user_id
} = require 'libs_backend/background_common'

{
  once_available
} = require 'libs_frontend/frontend_libs'



polymer_ext {
  is: 'popup-view'
  properties: {
    enabledInterventions: {
      type: Array
    },
    feedbackText: {
      type: String,
      notify: true
    },
    graphOptions: {
      type: Array
    },
    shownGraphs: {
      type: Array
    },
    graphNamesToOptions: {
      type: Object
    },
    blacklist: {
      type: Object
    },
    sites: {
      type: Array
    },
    html_for_shown_graphs: {
      type: String
      computed: 'compute_html_for_shown_graphs(shownGraphs, blacklist, sites)'
    },
    selected_tab_idx: {
      type: Number
      value: 0
    },
    selected_graph_tab: {
      type: Number,
      value: 0
    }
    goals_and_interventions: {
      type: Array
      value: []
    }
    intervention_name_to_info: {
      type: Object
      value: {}
    }
    #url_override: {
    #  type: String
    #}
    is_habitlab_disabled: {
      type: Boolean,
      value: true
    }
    stress_intervention_active: {
      type: Boolean,
    }
    stress_intervention_display: {
      type: Boolean
    }
    ask_intervention_done: {
      type: Boolean
    }
    intervention_stress_before: {
      type: Boolean
    }
    intervention_stress_after: {
      type: Boolean
    }
    stress_intervention_data: {
      type: String,
      value: null
    }
    stress_intervention_end: {
      type: String,
      value: null
    }
    stress_intervention_loading: {
      type: Boolean
    }
  }

  get_intervention_description: (intervention_name, intervention_name_to_info) ->
    return intervention_name_to_info[intervention_name].description

  noValidInterventions: ->
    return this.goals_and_interventions.length === 0

  temp_disable_button_clicked: (evt) ->>
    self = this
    intervention = evt.target.intervention
    # <- set_intervention_disabled intervention
    prev_enabled_interventions = await get_enabled_interventions()
    tab_info = await get_active_tab_info()
    url = tab_info.url
    enabledInterventions = await list_currently_loaded_interventions_for_tabid(tab_info.id)
    enabledInterventions = [x for x in enabledInterventions when x != intervention]
    self.enabledInterventions = enabledInterventions
    await disable_interventions_in_active_tab()
    this.fire 'disable_intervention'
    add_log_interventions {
      type: 'intervention_set_temporarily_disabled'
      page: 'popup-view'
      subpage: 'popup-view-active-intervention-tab'
      category: 'intervention_enabledisable'
      now_enabled: false
      is_permanent: false
      manual: true
      url: window.location.href
      tab_url: url
      intervention_name: intervention
      prev_enabled_interventions: prev_enabled_interventions
    }
    #swal({
    #  title: 'Disabled!',
    #  text: 'This intervention will be disabled temporarily.'
    #})

  perm_disable_button_clicked: (evt) ->>
    self = this
    intervention = evt.target.intervention
    prev_enabled_interventions = await get_enabled_interventions()
    await set_intervention_disabled_permanently intervention
    tab_info = await get_active_tab_info()
    url = tab_info.url
    enabledInterventions = await list_currently_loaded_interventions_for_tabid(tab_info.id)
    enabledInterventions = [x for x in enabledInterventions when x != intervention]
    self.enabledInterventions = enabledInterventions
    await disable_interventions_in_active_tab()
    this.fire 'disable_intervention'
    add_log_interventions {
      type: 'intervention_set_permanently_disabled'
      page: 'popup-view'
      subpage: 'popup-view-active-intervention-tab'
      category: 'intervention_enabledisable'
      now_enabled: false
      is_permanent: false
      manual: true
      url: window.location.href
      tab_url: url
      intervention_name: intervention
      prev_enabled_interventions: prev_enabled_interventions
    }
    #swal({
    #  title: 'Disabled!',
    #  text: 'This intervention will be disabled permanently.'
    #})

  is_not_in_blacklist: (graph, blacklist, graphNamesToOptions) ->
    graph = graphNamesToOptions[graph]
    return blacklist[graph] == false

  checkbox_checked_handler: (evt) ->
    self = this
    graph = evt.target.graph
    self.blacklist[self.graphNamesToOptions[graph]] = !evt.target.checked
    self.blacklist = JSON.parse JSON.stringify self.blacklist
    localstorage_setjson('popup_view_graph_blacklist', self.blacklist)

  sortableupdated: (evt) ->
    self = this
    shownGraphs = this.$$('#graphlist_sortable').innerText.split('\n').map((.trim())).filter((x) -> x != '')
    this.shownGraphs = shownGraphs.map((graph_name) -> self.graphNamesToOptions[graph_name])

  compute_html_for_shown_graphs: (shownGraphs, blacklist, sites) ->
    self = this
    shownGraphs = shownGraphs.filter((x) -> !self.blacklist[x])


    html = "<div class=\"card-content\">"
    for x in shownGraphs
      if x == 'site-goal-view'
        for site in sites

          html += "<#{x} site=\"#{site}\"></#{x}><br>"
      else
        html += "<#{x}></#{x}><br>"
    html += "</div>"
    return html

  isEmpty: (enabledInterventions) ->
    return enabledInterventions? and enabledInterventions.length == 0

  outside_work_hours: ->
    return is_it_outside_work_hours!

  disable_habitlab_changed: (evt) ->>
    if evt.target.checked
      this.is_habitlab_disabled = true
      disable_habitlab()
      tab_info = await get_active_tab_info()
      loaded_interventions = await list_currently_loaded_interventions_for_tabid(tab_info.id)
      add_log_habitlab_disabled({
        page: 'popup-view',
        reason: 'disable_button_slider_toggle'
        tab_info: tab_info
        url: tab_info?url
        loaded_interventions: loaded_interventions
        loaded_intervention: loaded_interventions[0]
      })
    else
      this.is_habitlab_disabled = false
      enable_habitlab()
      tab_info = await get_active_tab_info()
      loaded_interventions = await list_currently_loaded_interventions_for_tabid(tab_info.id)
      add_log_habitlab_enabled({
        page: 'popup-view',
        reason: 'disable_button_slider_toggle'
        tab_info: tab_info
        url: tab_info?url
        loaded_interventions: loaded_interventions
      })



  enable_habitlab_button_clicked: ->>
    this.is_habitlab_disabled = false
    enable_habitlab()
    tab_info = await get_active_tab_info()
    loaded_interventions = await list_currently_loaded_interventions_for_tabid(tab_info.id)
    add_log_habitlab_enabled({
      page: 'popup-view',
      reason: 'enable_habitlab_big_button_clicked'
      tab_info: tab_info
      loaded_interventions: loaded_interventions
    })

  goal_enable_button_changed: (evt) ->>
    goal = evt.target.goal
    if evt.target.checked
      # is enabling this goal
      if goal.name?
        await set_goal_enabled goal.name
      else
        await add_enable_custom_goal_reduce_time_on_domain goal.domain
      await this.set_goals_and_interventions!
    else
      # is disabling this goal
      await set_goal_disabled goal.name
      await this.set_goals_and_interventions!

  set_goals_and_interventions: ->>
    sites_promise = list_sites_for_which_goals_are_enabled()
    enabledInterventions_promise = list_currently_loaded_interventions()
    intervention_name_to_info_promise = get_interventions()
    all_goals_and_interventions_promise = get_nonpositive_goals_and_interventions()
    url_promise = get_active_tab_url()

    [
      sites
      enabledInterventions
      intervention_name_to_info
      all_goals_and_interventions
      url
    ] = await Promise.all [
      sites_promise
      enabledInterventions_promise
      intervention_name_to_info_promise
      all_goals_and_interventions_promise
      url_promise
    ]

    this.sites = sites
    this.enabledInterventions = enabledInterventions
    this.intervention_name_to_info = intervention_name_to_info

    domain = url_to_domain url

    filtered_goals_and_interventions = all_goals_and_interventions.filter (obj) ->

      return (obj.goal.domain == domain) # and obj.enabled

    if filtered_goals_and_interventions.length == 0
      filtered_goals_and_interventions = [
        {
          enabled: false
          goal: {
            domain: domain
            description: "Spend less time on #{domain}"
          }
        }
      ]
    this.goals_and_interventions = filtered_goals_and_interventions

  get_power_icon_src: ->
    return chrome.extension.getURL('icons/power_button.svg')

  get_thumbs_icon_src:->
    return chrome.extension.getURL('icons/thumbs_i')

  debug_button_clicked: ->>
    tab_id = await get_active_tab_id()
    await open_debug_page_for_tab_id(tab_id)

  submit_feedback_clicked: ->>
    #screenshot_utils = await SystemJS.import('libs_common/screenshot_utils')
    screenshot_utils = await get_screenshot_utils()
    screenshot = await screenshot_utils.get_screenshot_as_base64()
    data = await screenshot_utils.get_data_for_feedback()
    feedback_form = document.createElement('feedback-form')
    document.body.appendChild(feedback_form)
    feedback_form.screenshot = screenshot
    feedback_form.other = data
    feedback_form.open()

  help_icon_clicked: ->>
    await load_css_file('bower_components/sweetalert2/dist/sweetalert2.css')
    swal = await get_swal()
    swal {
      title: 'How HabitLab Works'
      html: '''
      HabitLab will help you achieve your goal by showing you a different <i>nudge</i>, like a news feed blocker or a delayed page loader, each time you visit your goal site.
      <br><br>
      At first, HabitLab will show you a random nudge each visit, and over time it will learn what works most effectively for you.
      <br><br>
      Each visit, HabitLab will test a new nudge and measure how much time you spend on the site. Then it determines the efficacy of each nudge by comparing the time spent per visit when that nudge was deployed, compared to when other nudges are deployed. HabitLab uses an algorithmic technique called <a href="https://en.wikipedia.org/wiki/Multi-armed_bandit" target="_blank">multi-armed-bandit</a> to learn which nudges work best and choose which nudges to deploy, to minimize your time wasted online.
      '''
      allowOutsideClick: true
      allowEscapeKey: true
      #showCancelButton: true
      #confirmButtonText: 'Visit Facebook to see an intervention in action'
      #cancelButtonText: 'Close'
    }

############# STRESS INTERVENTION FUNCTIONS


  start_stress_intervention: ->>
    this.stress_intervention_active = true
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = true
    this.intervention_stress_after = false
    this.intervention_end = false
    localstorage_setstring("current_panel", "stress_before")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)
    if (await localstorage_getbool('icon_nudge_active'))
      once_available("home_panel", this.set_nudge_message())
    #console.log(localstorage_getstring("current_panel", "stress_before"))
    # Create object to send to database
    #console.log("Data to send: ")
    #console.log(localstorage_getjson("intervention_data_tosend"))
    to_send = localstorage_getjson("intervention_data_tosend")
    # Add contextual data
    to_send["contextual_info"] = {}
    to_send["date"] = new Date()
    to_send["userid"] = await get_user_id()
    to_send["interventions_shown"] = []
    #console.log("Click rate buffer: ", await localstorage_getjson("click_rate_buffer"))
    #console.log(typeof(await localstorage_getjson("click_rate_buffer")))
    to_send["contextual_info"]["click_rate_buffer"] = await localstorage_getjson("click_rate_buffer")
    to_send["contextual_info"]["scroll_rate_buffer"] = await localstorage_getjson("scroll_rate_buffer")
    to_send["contextual_info"]["current_tab_info"] = await get_active_tab_info()
    localstorage_setjson("intervention_data_tosend", to_send)
    console.log(localstorage_getjson("intervention_data_tosend"))
    this.$$("input[name=stress_level]:checked").value = stress_level_before

  set_nudge_message: ->>
    this.$$('#intro_message').innerHTML = "Seems like you've been browsing for a while. Take a moment to destress."

  remove_nudge_message: ->>
    this.$$('#intro_message').innerHTML = "Take a sweet moment to destress."

  returnto_stress_before:->>
    this.stress_intervention_active = true
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = true
    this.intervention_stress_after = false
    this.intervention_end = false
    localstorage_setstring("current_panel", "stress_before")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)


  returnto_stress_after:->>
    this.stress_intervention_active = true
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = false
    this.intervention_stress_after = true
    this.intervention_end = false
    localstorage_setstring("current_panel", "stress_after")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)

  get_stress_intervention: ->>
    this.stress_intervention_active = true
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = false
    this.intervention_stress_after = false
    this.intervention_end = false
    this.stress_intervention_loading = true
    localstorage_setstring("current_panel", "intervention_loading")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)
    console.log("Requesting intervention from server...")
    this.intervention_data_received = await JSON.parse(await get_json(hso_server_url + "/getIntervention", []))
    console.log("Intervention received: " + JSON.stringify(this.intervention_data_received))
    #await sleep(5000)
    localstorage_setjson("selected_intervention_data", this.intervention_data_received)
    this.show_stress_intervention()

  show_stress_intervention: ->>
    this.stress_intervention_active = true
    this.stress_intervention_display = true
    this.ask_intervention_done = false
    this.intervention_stress_before = false
    this.intervention_stress_after = false
    this.intervention_end = false
    this.stress_intervention_loading = false
    this.icons =
      cognitive_behavioral: 'cog_behavioral.png'
      meta_cognitive: 'meta_cog.png'
      positive_psychology: 'positive_psych.png'
      productivity: 'Productivity.png'
      somatic: 'somatic.png'
    localstorage_setstring("current_panel", "intervention_display")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)
    console.log("Updating panel with intervention...")
    once_available("intervention_panel", this.update_intervention_panel())

  update_intervention_panel: ->>
    data = await localstorage_getjson("selected_intervention_data")
    console.log("Intervention data to display (Should match prev. data): " + JSON.stringify(data))
    this.$$('#intervention_text').innerHTML = data.text
    this.$$('#intervention_duration').innerHTML = data.duration
    this.$$('#intervention_title').innerHTML = "<b>Task: " + data.name + "<b>"
    #console.log("../icons/HSO_icons/" + this.icons[data.type])
    this.$$('#intervention_icon').src = "../icons/HSO_icons/" + this.icons[data.type]

  record_stress_before: ->>
    console.log("Recording stress before...")
    #await console.log(this.$$("input[name=stress_level]:checked").value)
    to_send = localstorage_getjson("intervention_data_tosend")
    stress_level_before = this.$$("input[name=stress_level]:checked").value
    to_send["stress_before"] = stress_level_before
    localstorage_setjson("intervention_data_tosend", to_send)
    #console.log(localstorage_getjson("intervention_data_tosend"))
    this.get_stress_intervention()

  record_stress_after: ->>
    if this.$$("input[name=stress_level_after]:checked") === null
      window.alert("Please select an option.")
      return
    to_send = localstorage_getjson("intervention_data_tosend")
    stress_change = this.$$("input[name=stress_level_after]:checked").value
    to_send["stress_change"] = stress_change
    localstorage_setjson("intervention_data_tosend", to_send)
    #console.log(localstorage_getjson("intervention_data_tosend"))
    this.show_final_panel()

  click_intervention_link: ->>
    this.ask_intervention_done = true
    this.stress_intervention_display = false
    this.intervention_stress_before = false
    this.intervention_stress_after = false
    this.intervention_end = false
    this.stress_intervention_loading = false
    localstorage_setstring("current_panel", "ask_intervention_done")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)
    data = await localstorage_getjson("selected_intervention_data")
    to_send = localstorage_getjson("intervention_data_tosend")
    #console.log(data["_id"])
    to_send["intervention_selected"] = data["_id"]
    localstorage_setjson("intervention_data_tosend", to_send)
    ##console.log(this.intervention_data_received.text)

    once_available("confirmation_panel", this.update_confirmation_panel())

    #await sleep(2000)

    this.intervention_timer = new Date() # TODO:  Change to localstorage variable
    #console.log(this.intervention_timer)
    #chrome.tabs.create({ url: this.intervention_data_received.url }, function(tab) {
    #  chrome.tabs.sendMessage(tab.id, {type: "action_example"})
    #});
    await if this.intervention_data_received.url !== "" then
      chrome.windows.create(url: this.intervention_data_received.url, top: 50px, left: 50px, width:1300, height:900)

  dismiss_intervention: ->
    if window.confirm("Are you sure you want to dismiss this sweet moment? You will have to exit the whole process.")
      this.stress_intervention_display = false
      this.ask_intervention_done = false
      this.intervention_stress_before = false
      this.intervention_stress_after = false
      this.intervention_end = true
      to_send = localstorage_getjson("intervention_data_tosend")
      localstorage_setstring("current_panel", "intervention_end")

      localstorage_setstring("panel_timer", (new Date()).getTime())
      localstorage_setbool('intervention_timed_out', false)
      localstorage_setbool('intervention_dismissed', true)
      to_send["intervention_completed"] = 0
      to_send["intervention_cancelled"] = 0
      to_send["intervention_dismissed"] = 1
      localstorage_setjson("intervention_data_tosend", to_send)


  update_confirmation_panel: ->>
    data = await localstorage_getjson("selected_intervention_data")
    this.$$('#confirmation_text').innerHTML = data.text
    this.$$('#confirmation_title').innerHTML = "Current Task: " + data.name

  show_userid : ->>
    userid = await get_user_id()
    this.$$('#userid_label').innerHTML = "UserID: " + userid

  intervention_confirmation: ->>
    #console.log("Ask intervention done again!")
    intervention = await localstorage_getjson("selected_intervention_data")
    #console.log(intervention.text)
    once_available('confirmation_panel', this.update_confirmation_panel())


  confirm_intervention_done: ->>
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = false
    this.intervention_stress_after = true
    this.intervention_end = false
    localstorage_setstring("current_panel", "stress_after")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)

    timer_done = new Date()
    timer_diff = Math.abs(this.intervention_timer - timer_done) / 1000
    to_send = localstorage_getjson("intervention_data_tosend")
    to_send["seconds_to_complete"] = timer_diff
    #console.log(timer_diff)
    localstorage_setjson("intervention_data_tosend", to_send)

  show_final_panel: ->>
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = false
    this.intervention_stress_after = false
    this.intervention_end = true
    to_send = localstorage_getjson("intervention_data_tosend")
    localstorage_setstring("current_panel", "intervention_end")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)
    to_send["intervention_completed"] = 1
    to_send["intervention_cancelled"] = 0
    localstorage_setjson("intervention_data_tosend", to_send)

  end_stress_intervention: ->>
    await this.send_intervention_data()
    console.log("Ending intervention")
    this.stress_intervention_active = false
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = false
    this.intervention_stress_after = false
    this.intervention_end = false
    localstorage_setstring("current_panel", "home")
    localstorage_setstring("panel_timer", (new Date()).getTime())
    localstorage_setbool('intervention_timed_out', false)

    localstorage_setbool('icon_nudge_active', false)
    localstorage_setstring('last_intervention', new Date().getTime())

    this.close_popup()
    #once_available("home_panel", this.remove_nudge_message())
    localstorage_setjson("intervention_data_tosend", {})


  get_feedback_text: ->>
    stored_data = localstorage_getjson("intervention_data_tosend")
    to_send = {}
    to_send["written_feedback"] = this.$$('#written_feedback').value
    to_send["date"] = stored_data["date"]
    to_send["userid"] = stored_data["userid"]
    to_send["intervention"] = stored_data["intervention_selected"]
    ##console.log(this.$$('#written_feedback').value)
    #localstorage_setjson("intervention_data_tosend", to_send)
    post_json(hso_server_url + "/postWrittenFeedback", to_send)


  submit_feedback: ->>
    #once_available("written_feedback", this.get_feedback_text())
    feedback = window.prompt("Write down your feedback: ")
    #this.$$('#written_feedback').value = ""
    to_send = localstorage_getjson("intervention_data_tosend")
    to_send["written_feedback"] = feedback
    await localstorage_setjson("intervention_data_tosend", to_send)
    #post_json(hso_server_url + "/postWrittenFeedback", to_send)
    alert("Feedback Submitted!")
    this.end_stress_intervention()

  ask_another_intervention: ->>
    to_send = localstorage_getjson("intervention_data_tosend")
    to_send["requested_another"] = 1
    localstorage_setjson("intervention_data_tosend", to_send)
    this.send_intervention_data()
    this.get_stress_intervention()

  send_intervention_data: ->>
    post_json(hso_server_url + "/postInterventionData", localstorage_getjson("intervention_data_tosend"))
    #console.log("Data sent: " + await JSON.stringify(localstorage_getjson("intervention_data_tosend")))


  confirm_cancel: ->>
    if window.confirm("Are you sure you want to exit the intervention?")
      this.cancel_stress_intervention()

  cancel_stress_intervention: ->>
    console.log("Cancelling intervention")
    this.stress_intervention_active = false
    this.stress_intervention_display = false
    this.ask_intervention_done = false
    this.intervention_stress_before = false
    this.intervention_stress_after = false
    this.intervention_end = false
    console.log("Cancelling stress intervention")
    #console.log(this.$$("input[name=stress_level]:checked").value)
    #this.$$("input[name=stress_level]").value = 0
    #this.$$("input[name=stress_level]:checked").prop('checked', false)
    stress_level_before = 0
    stress_change = null
    to_send = localstorage_getjson("intervention_data_tosend")
    to_send["intervention_completed"] = 0
    to_send["intervention_cancelled"] = 1
    to_send["intervention_cancelled_stage"] = await localstorage_getstring("current_panel")
    localstorage_setjson("intervention_data_tosend", to_send)
    localstorage_setstring("current_panel", "home")
    localstorage_setstring("panel_timer", "")
    this.send_intervention_data()

  #check_for_survey: ->>
    #userid = await get_user_id()
    #console.log("Sending request for survey data from user" + userid)
    #survey_data = JSON.parse(await get_json(hso_server_url + "/getSurvey", "userid=" + userid))
    #console.log("Received data: " + JSON.stringify(survey_data))
    #if Object.keys(survey_data).length !== 0
    #  localstorage_setjson("survey_data", survey_data)
    #  localstorage_setbool("icon_notif_active", true)
    #  once_available("survey_button", this.enable_survey_button())

  enable_survey_button: ->>
    survey_data = await localstorage_getjson("survey_data")
    button = document.getElementById("survey_button")
    button.innerHTML = survey_data.button_text
    button.style.display = "flex"
    button.disabled = false

  disable_survey_button: ->>
    localstorage_setjson("survey_data", {})
    button = document.getElementById("survey_button")
    button.style.display = "none"
    button.disabled = true

  survey_button_clicked: ->>
    survey_data = localstorage_getjson("survey_data")
    userid = await get_user_id()
    chrome.tabs.create {url: survey_data.url + '?habitlab_userid=' + userid + '&click_location=dropdown'}
    post_json(hso_server_url + "/surveyClicked", {"_id": survey_data._id, "userid":userid,"click_location":"dropdown"})
    this.disable_survey_button()

  close_popup: ->
    window.close()

  results_button_clicked: ->
    chrome.tabs.create {url: 'options.html#overview'}

  settings_button_clicked: ->
    chrome.tabs.create {url: 'options.html#settings'}

  ready: ->>
    #chrome.browserAction.setBadgeText {text: ''}
    #chrome.browserAction.setBadgeBackgroundColor {color: '#000000'}
    self = this
    # CHANGED THIS LINE FOR HSO MVP PILOT
    #is_habitlab_enabled().then (is_enabled) -> self.is_habitlab_disabled = !is_enabled
    is_habitlab_disabled = true

    #FILTER THIS FOR ONLY THE CURRENT GOAL SITE#
    await this.set_goals_and_interventions!

    have_enabled_custom_interventions = self.enabledInterventions.map(-> self.intervention_name_to_info[it]).filter(-> it?custom).length > 0
    if self.enabledInterventions.length > 0 and (localstorage_getbool('enable_debug_terminal') or have_enabled_custom_interventions)
      self.S('#debugButton').show()

    if self.enabledInterventions.length == 0
      self.selected_tab_idx = 1

    localstorage_setbool('popup_view_has_been_opened', true)

    # Check localstorage for current panel
    panel = localstorage_getstring("current_panel")

    #console.log(panel)
    if typeof(panel) === 'undefined' or panel === null
      localstorage_setstring("current_panel", "home")
      panel = "home"

    # Check if intervention session timed out to reset panel
    if localstorage_getbool('intervention_timed_out')
      localstorage_setbool('intervention_timed_out', false)
      panel = "home"


    # If intervention data undefined, set to empty object
    if localstorage_getjson("intervention_data_tosend") === null
      ##console.log("Data to send undefined")
      localstorage_setjson("intervention_data_tosend", {})

    # Show appropriate panel
    if panel === "home"
      this.stress_intervention_active = false
      if (await localstorage_getbool('icon_nudge_active'))
        once_available("home_panel", this.set_nudge_message())
    else if panel === "stress_before"
      ##console.log("Showing stress before panel")
      this.stress_intervention_active = true
      this.intervention_stress_before = true
    else if panel === "stress_after"
      ##console.log("Showing stress after panel")
      this.stress_intervention_active = true
      this.intervention_stress_after = true
    else if panel === "intervention_loading"
      ##console.log("Showing intervention display")
      this.stress_intervention_active = true
      this.stress_intervention_loading = true
      this.show_stress_intervention()
    else if panel === "intervention_display"
      ##console.log("Showing intervention display")
      this.stress_intervention_active = true
      this.stress_intervention_display = true
      this.show_stress_intervention()
    else if panel === "ask_intervention_done"
      ##console.log("Showing ask intervention done")
      this.stress_intervention_active = true
      this.ask_intervention_done = true
      this.intervention_confirmation()
    else if panel === "intervention_end"
      ##console.log("Showing intervention end")
      this.stress_intervention_active = true
      this.intervention_end = true

    # Check if survey available to update button
    survey_data = await localstorage_getjson("survey_data")
    if typeof(survey_data) === 'undefined' or survey_data === null
      localstorage_setjson("survey_data",{})
      #console.log("No previous survey data. Sending request for new...")
      #this.check_for_survey()
    else if Object.keys(survey_data).length !== 0
      localstorage_setbool('icon_notif_active', true)
      once_available("survey_button", this.enable_survey_button())
    #else
      #console.log("Survey data empty. Sending request for new...")
      #this.check_for_survey()

    once_available("userid_label", this.show_userid())

    setTimeout ->>
      require('../bower_components/iron-icon/iron-icon.deps')
      require('../bower_components/iron-icons/iron-icons.deps')
      require('components/graph-donut-top-sites.deps')
      require('components/intervention-view-single-compact.deps')
      require('components/feedback-form.deps')

      await get_screenshot_utils()
      await get_swal()
    , 1
}, {
  source: require 'libs_frontend/polymer_methods'
  methods: [
    'S'
  ]
}
