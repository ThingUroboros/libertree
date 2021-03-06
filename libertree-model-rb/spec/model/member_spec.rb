require 'spec_helper'

describe Libertree::Model::Member do
  describe '#after_create' do
    it 'creates a distribution job' do
      Libertree::Model::Job.should_receive(:create_for_forests)
      @account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
      @member = @account.member
    end
  end

  describe '#after_update' do
    context 'with existing member' do
      before :each do
        @account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
        @member = @account.member
      end

      it 'creates a distribution job whenever the member record is updated' do
        Libertree::Model::Job.should_receive(:create_for_forests)
        @member.avatar_path = "/new/path"
        @member.save
      end
    end
  end

  describe '#handle' do
    it 'returns the username and domain part for local and remote members' do
      account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
      local = account.member
      expect( local.handle ).to eq(account.username + '@' + Libertree::Model::Server.own_domain)

      server = Libertree::Model::Server.create( FactoryGirl.attributes_for(:server) )
      remote = Libertree::Model::Member.create(
        FactoryGirl.attributes_for(:member, :server_id => server.id)
      )
      expect( remote.handle ).to eq(remote.username + '@' + server.domain)
    end
  end

  describe '.with_handle' do
    it 'gets the member record with a matching handle on a remote server' do
      @server = Libertree::Model::Server.create( FactoryGirl.attributes_for(:server) )
      @member = Libertree::Model::Member.create(
        FactoryGirl.attributes_for(:member, :server_id => @server.id)
      )
      expect( Libertree::Model::Member.with_handle(@member.handle) ).to eq(@member)
    end

    it 'gets the member record with a matching handle on the local server' do
      account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
      @member = account.member
      expect( Libertree::Model::Member.with_handle(@member.handle) ).to eq(@member)
    end
  end

  describe '.search' do
    before :all do
      Libertree::DB.dbh.execute 'TRUNCATE members CASCADE'
      Libertree::DB.dbh.execute 'TRUNCATE accounts CASCADE'
    end
    it 'returns local and remote members if username or display name match' do
      account1 = Libertree::Model::Account.create({username: 'test',  password_encrypted: '1234'})
      member1 = account1.member

      remote = Libertree::Model::Server.create( FactoryGirl.attributes_for(:server) )
      member2 = Libertree::Model::Member.create({username: 'remote', server_id: remote.id})
      member2.profile.name_display = "Tester"
      member2.profile.save

      member3 = Libertree::Model::Member.create({username: 'testing', server_id: remote.id})
      member3.profile.name_display = "whatever"
      member3.profile.save

      member4 = Libertree::Model::Member.create({username: 'dontcare', server_id: remote.id})
      member4.profile.name_display = "don't care"
      member4.profile.save

      expect( Libertree::Model::Member.search("test") ).to match_array([member1, member2, member3])
    end
  end
end
