require 'rack'
require 'flash'
require 'controller_base'
require 'byebug'

describe Flash do
  let(:req) { Rack::Request.new({'rack.input' => {}}) }
  let(:res) { Rack::Response.new([], '200', {}) }
  let(:cook) { {"flash" => { "normal_flash" => {'xyz' => 'abc' } }.to_json} }

  it "deserializes json cookie if one exists" do
    req.cookies.merge!(cook)
    flash = Flash.new(req)
    expect(flash['xyz']).to eq('abc')
  end

  describe "#store_flash" do
    context "without cookies in request" do
      before(:each) do
        flash = Flash.new(req)
        flash['first_key'] = 'first_val'
        flash.store_flash(res)
      end

      it "adds new cookie with 'flash' name to response" do
        cookie_str = res.headers['Set-Cookie']
        cookie = Rack::Utils.parse_query(cookie_str)
        expect(cookie["flash"]).not_to be_nil
      end

      it "stores the cookie in json format" do
        cookie_str = res.headers['Set-Cookie']
        cookie = Rack::Utils.parse_query(cookie_str)
        cookie_val = cookie["flash"]
        cookie_hash = JSON.parse(cookie_val)
        expect(cookie_hash).to be_instance_of(Hash)
      end
    end

    context "with cookies in request" do
      before(:each) do
        cook = {'flash' => {'normal_flash' => { 'pho' =>  "soup" } }.to_json }
        req.cookies.merge!(cook)
      end

      it "reads the pre-existing cookie data into hash" do
        flash = Flash.new(req)
        expect(flash['pho']).to eq('soup')
      end

      it "saves new and old data to the cookie" do
        flash = Flash.new(req)
        flash['machine'] = 'mocha'
        flash.store_flash(res)
        cookie_str = res['Set-Cookie']
        cookie = Rack::Utils.parse_query(cookie_str)
        cookie_val = cookie["flash"]["normal_flash"]
        cookie_hash = JSON.parse(cookie_val)
        expect(cookie_hash['pho']).to eq('soup')
        expect(cookie_hash['machine']).to eq('mocha')
      end
    end
  end
end

describe ControllerBase do
  before(:all) do
    class CatsController < ControllerBase
    end
  end
  after(:all) { Object.send(:remove_const, "CatsController") }

  let(:req) { Rack::Request.new({'rack.input' => {}}) }
  let(:res) { Rack::Response.new([], '200', {}) }
  let(:cats_controller) { CatsController.new(req, res) }

  describe "#flash" do
    it "returns a flash instance" do
      expect(cats_controller.flash).to be_a(Flash)
    end

    it "returns the same instance on successive invocations" do
      first_result = cats_controller.flash
      expect(cats_controller.flash).to be(first_result)
    end
  end

  shared_examples_for "storing flash data" do
    it "should store the flash data" do
      cats_controller.flash['test_key'] = 'test_value'
      cats_controller.send(method, *args)
      cookie_str = res['Set-Cookie']
      cookie = Rack::Utils.parse_query(cookie_str)
      cookie_val = cookie["flash"]
      cookie_hash = JSON.parse(cookie_val)
      expect(cookie_hash['test_key']).to eq('test_value')
    end
  end

  describe "#render_content" do
    let(:method) { :render_content }
    let(:args) { ['test', 'text/plain'] }
    include_examples "storing flash data"
  end

  describe "#redirect_to" do
    let(:method) { :redirect_to }
    let(:args) { ['http://appacademy.io'] }
    include_examples "storing flash data"
  end
end
