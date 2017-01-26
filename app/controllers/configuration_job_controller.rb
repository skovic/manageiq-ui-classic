class ConfigurationJobController < ApplicationController
  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  include Mixins::GenericListMixin
  include Mixins::GenericSessionMixin

  def self.model
    ManageIQ::Providers::AnsibleTower::AutomationManager::Job
  end

  def self.table_name
    @table_name ||= "configuration_job"
  end

  def ems_path(*args)
    ems_configprovider_path(*args)
  end

  def show
    return if perfmenu_click?
    @display = params[:display] || "main" unless pagination_or_gtl_request?

    @lastaction = "show"
    @configuration_job = @record = identify_record(params[:id])
    return if record_no_longer_exists?(@configuration_job)

    @gtl_url = "/show"
    drop_breadcrumb({:name => _("Configuration_Jobs"),
                     :url  => "/configuration_job/show_list?page=#{@current_page}&refresh=y"}, true)
    case @display
    when "main", "summary_only"
      get_tagdata(@configuration_job)
      drop_breadcrumb(:name => _("%{name} (Summary)") % {:name => @configuration_job.name},
                      :url  => "/configuration_job/show/#{@configuration_job.id}")
      @showtype = "main"
      set_summary_pdf_data if @display == 'summary_only'
    end

    replace_gtl_main_div if pagination_request?
  end

  def parameters
    show_association('parameters', _('Parameters'), 'parameter', :parameters, OrchestrationStackParameter)
  end

  # handle buttons pressed on the button bar
  # handle buttons pressed on the button bar
  def button
    @edit = session[:edit] # Restore @edit for adv search box
    params[:page] = @current_page if @current_page.nil? # Save current page for list refresh

    params[:page] = @current_page if @current_page.nil? # Save current page for list refresh
    @refresh_div = "main_div" # Default div for button.rjs to refresh
    case params[:pressed]
    when "configuration_job_delete"
      configuration_job_delete
    when "configuration_job_tag"
      tag(ManageIQ::Providers::AnsibleTower::AutomationManager::Job)
    end
    return if %w(configuration_job_tag).include?(params[:pressed]) && @flash_array.nil? # Tag screen showing, so return

    if @flash_array.nil? && !@refresh_partial # if no button handler ran, show not implemented msg
      add_flash(_("Button not yet implemented"), :error)
      @refresh_partial = "layouts/flash_msg"
      @refresh_div = "flash_msg_div"
    elsif @flash_array && @lastaction == "show"
      @configuration_job = @record = identify_record(params[:id])
      @refresh_partial = "layouts/flash_msg"
      @refresh_div = "flash_msg_div"
    end

    if !@flash_array.nil? && params[:pressed] == "configurations_job_delete" && @single_delete
      javascript_redirect :action => 'show_list', :flash_msg => @flash_array[0][:message]
    elsif @refresh_div == "main_div" && @lastaction == "show_list"
      replace_gtl_main_div
    else
      render_flash
    end
  end

  def title
    _("Job")
  end

  menu_section :conf
end
