require 'test/helper'

##
# Test template extensions rendering and things related to views.
#
class Admin::CommentsControllerTest < ActionController::TestCase

  def setup
    @typus_user = typus_users(:admin)
    @request.session[:typus_user_id] = @typus_user.id
    @comment = comments(:first)
  end

  def test_should_render_comments_partials_on_index
    get :index
    assert_response :success
    partials = %w( _index.html.erb _sidebar.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

  def test_should_render_comments_partials_on_new
    get :new
    assert_response :success
    partials = %w( _new.html.erb _sidebar.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

  def test_should_render_comments_partials_on_edit
    get :edit, { :id => @comment.id }
    assert_response :success
    partials = %w( _edit.html.erb _sidebar.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

  def test_should_render_comments_partials_on_show
    get :show, { :id => @comment.id }
    assert_response :success
    partials = %w( _show.html.erb _sidebar.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

  def test_should_verify_page_title_on_index
    get :index
    assert_select 'title', "#{Typus::Configuration.options[:app_name]} - Comments"
  end

  def test_should_verify_page_title_on_new
    get :new
    assert_select 'title', "#{Typus::Configuration.options[:app_name]} - Comments &rsaquo; New"
  end

  def test_should_verify_page_title_on_edit
    comment = comments(:first)
    get :edit, :id => comment.id
    assert_select 'title', "#{Typus::Configuration.options[:app_name]} - Comments &rsaquo; Edit"
  end

  def test_should_show_add_new_link_in_index
    get :index
    assert_response :success
    assert_match 'Add entry', @response.body
  end

  def test_should_not_show_add_new_link_in_index

    typus_user = typus_users(:designer)
    @request.session[:typus_user_id] = typus_user.id

    get :index
    assert_response :success
    assert_no_match /Add comment/, @response.body

  end

  def test_should_show_trash_item_image_and_link_in_index
    get :index
    assert_response :success
    assert_match /trash.gif/, @response.body
  end

  def test_should_not_show_remove_item_link_in_index

    typus_user = typus_users(:designer)
    @request.session[:typus_user_id] = typus_user.id

    get :index
    assert_response :success
    assert_no_match /trash.gif/, @response.body

  end

  def test_should_verify_new_comment_contains_a_link_to_add_a_new_post
    get :new
    match = '/admin/posts/new?back_to=%2Fadmin%2Fcomments%2Fnew&amp;selected=post_id'
    assert_match match, @response.body
  end

  def test_should_verify_edit_comment_contains_a_link_to_add_a_new_post
    comment = comments(:first)
    get :edit, :id => comment.id
    match = "/admin/posts/new?back_to=%2Fadmin%2Fcomments%2Fedit%2F#{comment.id}&amp;selected=post_id"
    assert_match match, @response.body
  end

  def test_should_generate_csv

    expected = <<-RAW
Email,Post
john@example.com,1
me@example.com,1
john@example.com,
me@example.com,1
     RAW

    get :index, :format => 'csv'
    assert_equal expected, @response.body

  end

end