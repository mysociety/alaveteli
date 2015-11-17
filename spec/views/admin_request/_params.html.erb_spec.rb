# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'when showing diffs in info_request params' do
  def do_render(params)
    render :partial => 'admin_request/params', :locals => {:params => params}
  end

  it 'should differentiate between old, new and other' do
    ire = InfoRequestEvent.new
    ire.params = { :old_foo => 'this is stuff', :foo => 'stuff', :bar => 84 }
    do_render(ire.params_diff)
    expect(response.body.squish).to match("<em>foo:</em> this is stuff => stuff <br> <em>bar:</em> 84 <br>")
  end

  it "should convert linebreaks to '<br>'s" do
    ire = InfoRequestEvent.new
    ire.params = { :old_foo => 'this\nis\nstuff', :foo => 'this\nstuff', :bar => 84 }
    do_render(ire.params_diff)
    expect(response.body.squish).to match("<em>foo:</em> this<br>is<br>stuff => this<br>stuff <br> <em>bar:</em> 84 <br>")
  end

  it 'should not report unchanged values as new' do
    ire = InfoRequestEvent.new
    ire.params = { :old_foo => 'this is stuff', :foo => 'this is stuff', :bar => 84 }
    do_render(ire.params_diff)
    expect(response.body.squish).to match("<em>bar:</em> 84 <br>")
  end
end
