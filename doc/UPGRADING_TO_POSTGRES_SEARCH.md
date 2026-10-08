# Upgrade notes to switch to Postgresql search

The new search engine is based on Postgresql, and replaces Xapian.

There is a long explanation for the reasons behind this switch in [SEARCH.md]. This page focuses on what needs to be done when upgrading to the new Alaveteli version and search system.

## Planning your upgrade

### Hardware requirements

As we index a lot more content for search, the storage requirements have gone up a bit.

While it is difficult to give an exact disk size required, below are some ballpark figures, based on observation done on a real dataset (for madada.fr). Each site will be different, depending on the number of users, requests, etc... but mostly on how many attachments a request typically receives in a response.

The following 2 estimates can help. They will likely give you somewhat different results, but be close enough to guide your work.

- double your existing Postgresql database size (which you can get with `\l+` in psql), then add the size for emails and attachments (see below)
- also look at the size of your xapian database (the `.glass` files under <alaveteli_root>/xapiandbs (unless you have set a different path in `config/xapian.yml`). Add this to the current size of your postgresql database . Then add the size for emails and attachments as above.


For emails and attachments:
- emails: take the size of the `incoming_messages` table with `\dt+ incoming_messages` in psql. Multiply by 2.5. This gives you `A`.
- attachments: take the size of the files on disk (or on S3 if you are using cloud storage) with `du -sh storage/attachments/` and multiply by 0.15. This is `B`, and it's most likely the biggest number of all.

Add A + B + the numbers above, to get 2 estimates of how much disk space you will need.

Eventually, you will get rid of the xapian files, so that much space will be freed.

Also note that Alaveteli won't automatically index everything in one go, and the indexing process can be interrupted and restarted without causing any problem. So if you see your disk filling up more than expected, you can stop the indexing process, resize disks and restart.

### CPU / Memory

You shouldn't need more than what you are currently using, possibly less.

## Upgrading

- If you need more disk space as mentioned above, plan this first.
- Follow the upgrade notes in [doc/CHANGES.md] as you usually do. At this point, you should be running on the new version. Then continue with the steps below.
 
### Index content in postgresql

For most installations, running the following commands in the rails console should be sufficient:

```ruby
Citation.reindex_all
Comment.reindex_all
PublicBody.reindex_all
User.reindex_all
InfoRequest.reindex_all
InfoRequestEvent.reindex_all
MailServerLog.reindex_all
OutgoingMessage.reindex_all
IncomingMessage.reindex_all
FoiAttachment.reindex_all
```

Running them one by one in the order above (which is roughly from fastest to slowest) should be fine. For bigger installations, you might want to exit the console between each line and restart it to free up resources (a more robust indexing script will be added to the codebase soon).

While the first ones will complete in less than a second, indexing FoiAttachment could take a long time (up to several days for sites with tens of thousands of attachments).

Note that your site will remain functional while reindexing is happening, and you will see search results growing along the process.

This should be the only time a full reindex is needed. The search system will stay updated automatically from then on.

At this point, you can update your `config/general.yml` to set `SEARCH_BACKEND=postgresql` and restart with the new search engine.

### Verify that search is working correctly

Confirm that you can find public bodies in the admin interface, as well as users and info requests. If you have indexed all contents, you should now be able to also find attachments from keywords in them.

### Remove Xapian files

If everything is working fine, remove the xapian files:

```bash
$ cd <alaveteli_root>/xapiandbs
$ rm -rf production
```
