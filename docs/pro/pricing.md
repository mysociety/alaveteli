---
layout: page
title: Alaveteli Pro Pricing
---

# Alaveteli Pro Pricing

<p class="lead">
    So you've got Pro running, how about asking users to support your work by
    paying for access to the advanced features?
</p>

This page describes the Pro Pricing feature. It explains how to set-up and
configure a payment gateway which can take regular payments from pro users
to grant them access to Alaveteli Professional.

The Pro Pricing feature is enabled with the [`ENABLE_PRO_PRICING`](
  #enable_pro_pricing
) configuration setting.

With the feature enabled, users will be able to submit their bank card details
and subscribe to a recurring subscription plan which will give them access to
all the professional features.

## Payment gateway

For a payment gateway Alaveteli Professional uses [Stripe](https://stripe.com).
It is widely available around the world and is easy to configure and work with.

The main advantage of Stripe is that all payment information is entered and sent
directly to Stripe. They never gets transmitted to or via your Alaveteli
installation so the security and data protection of those details are not a
concern for you.

### Creating an account

Signing up for an account with Stripe is quick and easy. Initially your account
will be a limited test account.

Before you can take payments you will need to activate your account. You will
need to provide legal information on you and/or your company as well as your
bank details in order receive payments.

Once approved by Stripe you'll then be able to receive payments and Stripe will
transfer the money directly into your bank account.

## Stripe configuration

Stripe provides a secure and robust Application Programming Interface or API
which Alaveteli Professional uses to communicate with Stripe. In order to use
this we require some configuration settings from your Stripe dashboard.

Follow the instructions below to set this up for your Alaveteli installation.

* [API keys](#api-keys)
* [Webhook endpoint](#webhook-endpoint)
* [Setting up the subscription product](#setting-up-the-subscription-product)
* [Creating coupons](#creating-coupons)
* [Using a namespace](#using-a-namespace)

### API keys

For Alaveteli Professional to communicate securly with Stripe you'll need to
generate a pair of [standard API keys](https://dashboard.stripe.com/apikeys) and
add the [`STRIPE_PUBLISHABLE_KEY`](#stripe_publishable_key) and
[`STRIPE_SECRET_KEY`](#stripe_secret_key) settings.

### Webhook endpoint

Stripe uses [webhooks](https://stripe.com/docs/webhooks) to inform the Alaveteli
installation of important events, such as when a users bank card can't be
charged or when a subscription has been cancelled.

The easiest way to set up the Webhook endpoint is using a rake task this can be
run from the command console:

<pre><code>bash$ bin/rails stripe:create_webhook_endpoint
Webhook endpoint successfully created!
Add this line to your general.yml config file:
  STRIPE_WEBHOOK_SECRET: whdec_u60BqwV5r4V4U7WmVRTuBgoR1NrPv6E4
</code></pre>

It outputs the value for [`STRIPE_WEBHOOK_SECRET`](#stripe_webhook_secret) which
should be set in `config/general.yml`.

### Setting up the subscription product

A subscription product in Stripe needs to be [created](
  https://dashboard.stripe.com/subscriptions/products/create
). We recommend "Pro", but this can have any name you wish but bear in mind that
this name will be displayed to users.

Once a product is created you'll then be asked to set-up its the pricing plan.
The pricing plan should be have the ID of `pro`, be for a recurring quantity and
without multiple price tiers. You should set a memorable nickname for the plan
but, again, bear in mind that this will be displayed to users.

Currently we only support monthly or yearly billing interval.

It's will be up to you to decide the price per unit and trial period.

### Creating coupons

Coupons can be [created](
  https://dashboard.stripe.com/coupons/create
)
on Stripe. There are no limitations on the types of coupons created as all
price calculations and adjustments are done by Stripe.

One coupon you might want to make is the [pro referral coupon](
  #pro_referral_coupon
). This is displayed to pro users and they are encouraged to share it with other
interested users.

### Using a namespace

It's possible you might have other coupons or plans already in Stripe. In this
case you'll want to set the [`STRIPE_NAMESPACE`](#stripe_namespace)
configuration setting.

If this setting is used the all Stripe pricing plan IDs and coupon codes will
need to be prefixed with the namespace like: `<namespace>-<ID or code>` this
should include the hyphen the namespace.

This will prevent users from using coupons intended for other non-Alaveteli Pro
subscription products.

<div class="attention-box info">
    While this setting is optional we recommend using this and setting it from
    the beginning. If set at a later date then your Stripe pricing plan IDs and
    coupon codes will need to be recreated with prefixed with the namespace.
</div>

## Stripe email notifications

Stripe will automatically send out emails to customers in certain situations if
configured to do so, you may want to consider:

### Successful payments

In the [email settings](https://dashboard.stripe.com/account/emails) you can
configure Stripe to email users when they are successfully charged. Alaveteli
does not send these, so we recommend enabling this.

### Failed payments

On the [billing email settings](
  https://dashboard.stripe.com/account/billing/automatic
) the 'Send emails when card payments fail' setting should be disabled. These
emails are sent directly from Alaveteli Professional.

## Limitations

### Don't add subscription from the Stripe dashboard

Currently it is not possible to use the dashboard to manually create
subscriptions. If this is done your Alaveteli installation will end up out of
sync with Stripe and users could be charged without being granted access to the
professional features.

## Testing Pro Pricing

You may wish to test Pro Pricing before enabling the [`ENABLE_PRO_PRICING`](
  #enable_pro_pricing
) configuration setting. This can be done on a per user basis from the command
console:

<pre><code>bash$ bin/rails console
irb(main):001:0> user = User.find_by(email: 'YOUR_EMAIL_ADDRESS')
irb(main):002:0> AlaveteliFeatures.backend.enable(:pro_pricing, user)
</code></pre>

## Translations

Enabling Pricing also enables [a “legal” page](https://git.io/JJoFI) and
[counterpart sidebar](https://git.io/JJoFq) that you’ll need to translate in the
[same way as help pages]({{ page.baseurl }}/docs/customising/translation/). In
this case you must locate the templates in `lib/views/alaveteli_pro/pages` in
your theme.

## Configuration settings

The following are all the configuration settings that you can change in
`config/general.yml`. When you edit this file, remember it must be in the <a
href="http://yaml.org">YAML syntax</a>. It's not complicated but &mdash;
especially if you're editing a list &mdash; be careful to get the indentation
correct. If in doubt, look at the examples already in the file, and don't use
tabs.

<code><a href="#enable_pro_pricing">ENABLE_PRO_PRICING</a></code>
<br> <code><a href="#stripe_publishable_key">STRIPE_PUBLISHABLE_KEY</a></code>
<br> <code><a href="#stripe_secret_key">STRIPE_SECRET_KEY</a></code>
<br> <code><a href="#stripe_namespace">STRIPE_NAMESPACE</a></code>
<br> <code><a href="#stripe_webhook_secret">STRIPE_WEBHOOK_SECRET</a></code>
<br> <code><a href="#pro_referral_coupon">PRO_REFERRAL_COUPON</a></code>

---

## All the Pro Pricing settings

<dl class="glossary">
  <dt>
    <a name="enable_pro_pricing"><code>ENABLE_PRO_PRICING</code></a>
  </dt>
  <dd>
    Setting this will enable the Pro Pricing feature for all users.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>ENABLE_PRO_PRICING: true</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_publishable_key"><code>STRIPE_PUBLISHABLE_KEY</code></a> &amp;
    <a name="stripe_secret_key"><code>STRIPE_SECRET_KEY</code></a>
  </dt>
  <dd>
    API keys for your Stripe account. These can be found in the Stripe.com
    developer dashboard.

    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li><code>STRIPE_PUBLISHABLE_KEY: pk_test_6rCXFw20WPjhMArF2Y3JquI2</code></li>
        <li><code>STRIPE_SECRET_KEY: sk_test_pLEJl474WdGWt5Pz8KCUZo3F</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_namespace"><code>STRIPE_NAMESPACE</code></a>
  </dt>
  <dd>
    An optional Stripe.com namespace which allows plans & coupons to be
    separated from other resources within Stripe. If used the Stripe resources
    will need IDs like: '&lt;namespace&gt;-&lt;id&gt;'

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>STRIPE_NAMESPACE: alaveteli</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_webhook_secret"><code>STRIPE_WEBHOOK_SECRET</code></a>
  </dt>
  <dd>
    Webhook key for your Stripe account. These can be found in the Stripe.com
    developer dashboard.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>WEBHOOK_SECRET: wh_test_UD6BDsARFZIYb8273dbdl</code></li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_referral_coupon"><code>PRO_REFERRAL_COUPON</code></a>
  </dt>
  <dd>
    <p>A Stripe coupon code – displayed to existing Pro users on their
    subscriptions page – that they can share with friends for their friends to
    receive a signup discount.</p>

    <p>This should <strong>not</strong> include the <code>STRIPE_NAMESPACE</code>.</p>

    <p>You <strong>must</strong> set a `humanized_terms` key in the Coupon
    Metadata to display the discount that will be applied when using the coupon
    (e.g. "50% off for 1 month").</p>

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li><code>PRO_REFERRAL_COUPON: PROREFERRAL</code></li>
      </ul>
    </div>
  </dd>
</dl>
