require 'json'

module Libertree
  module Model
    class Notification < Sequel::Model(:notifications)
      def account
        @account ||= Account[self.account_id]
      end

      def data
        if val = super
          JSON.parse val
        end
      end

      def subject
        @subject ||= case self.data['type']
        when 'comment'
          Libertree::Model::Comment[ self.data['comment_id'] ]
        when 'comment-like'
          Libertree::Model::CommentLike[ self.data['comment_like_id'] ]
        when 'message'
          Libertree::Model::Message[ self.data['message_id'] ]
        when 'post-like'
          Libertree::Model::PostLike[ self.data['post_like_id'] ]
        when 'springing'
          Libertree::Model::PoolPost[ self.data['pool_post_id'] ]
        when 'mention'
          Libertree::Model::Post[ self.data['post_id'] ]
        end
      end

      def self.mark_seen_for_account_and_comment_id(account, comment_ids)
        data = comment_ids.map {|id| %|{"type":"comment","comment_id":#{id.to_i}}| }
        data += CommentLike.where(comment_id: comment_ids).
          map {|like| %|{"type":"comment-like","comment_like_id":#{like.id}}| }

        self.where(account_id: account.id, data: data).update(seen: true)
        account.dirty
      end

      def self.mark_seen_for_account_and_post(account, post)
        data = post.likes.map {|like| %|{"type":"post-like","post_like_id":#{like.id.to_i}}| }
        self.where(account_id: account.id, data: data).update(seen: true)
        account.dirty
      end

      def self.mark_seen_for_account_and_message(account, message)
        self.where("account_id = ? AND data = ?", account.id, %|{"type":"message","message_id":#{message.id}}|).
          update(seen: true)
        account.dirty
      end

      def self.mark_seen_for_account(account, notification_ids)
        if notification_ids[0] == 'all'
          self.where(account_id: account.id).update(seen: true)
        else
          self.where(account_id: account.id, id: notification_ids).
            update(seen: true)
        end
        account.dirty
      end

      def self.mark_unseen_for_account(account, notification_ids)
        self.where(account_id: account.id, id: notification_ids).
          update(seen: false)
        account.dirty
      end
    end
  end
end
