require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'byebug'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = req.params
    @params.merge!(route_params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    flash.reset!
    if already_built_response?
      raise "Response already built!"
    else
      res.header["location"] = url
      res.status = 302
      session.store_session(res)
      flash.store_flash(res)
      flash.reset!
      @already_built_response = res
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    if already_built_response?
      raise "Response already built!"
    else
      res.body = [content]
      res.header['Content-Type'] = content_type
      session.store_session(res)
      flash.store_flash(res)
      flash.reset!
      @already_built_response = res
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    snaked_class = self.class.to_s.underscore
    template_file_path =
      ERB.new("views/#{snaked_class}/#{template_name}.html.erb").result(binding)
    content = File.read(template_file_path)
    content_template = ERB.new(content).result(binding)
    render_content(content_template, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  def flash
    @flash ||= Flash.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end
end
