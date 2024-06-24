---
tags:
  - cryptography
  - gnupg
  - security
---

# GnuPG Key Management

Original title: "Proper Key Management"

[permalink](https://reddit.com/r/GnuPG/comments/vjas2e/proper_key_management/)
by *Saklad5*

---

I've been using GnuPG for years now, and I've noticed that a lot of people misunderstand or overlook
the intent of many features. People encounter the same thorny problems over and over, not realizing
they've already been solved to some degree.

With that in mind, I thought I'd share my own advice on the ideal way to use GnuPG (and OpenPGP
in general). If you don't feel like reading through all of it, skip to the bottom for the most
important feature no one uses.

---

## User IDs

Each UID is tied directly to a primary key, on a many-to-one basis. The same is true for subkeys.
This means that every subkey is tied to *every* UID, and vice versa.

If you want subkeys that are only tied to specific UIDs, you should make a new primary key. For
instance, if you want to sign your Git commits on your work computer, you should make a new primary
key with your work email as a UID, then use signing subkeys of that. That way, the signing keys can
only be used in the name of your work identity, and your other signing keys cannot be used to do the
same.

Using multiple UIDs on the same primary key is only reasonable if you use all of them in the same
capacity, or otherwise want to share subkeys between them.

## Subkeys

PGP keys have four functions. Two are fungible: signing and authenticating. This means that the
specific key used to perform them isn't meaningful, and they can be used interchangeably so long
as they share the same primary key. This means you can (and should) generate a new subkey for the
purpose on each device you have, and avoid having multiple copies of them at all. When you stop
using an old device, revoke these keys accordingly. Don't even worry about losing access to them:
they are trivially replaceable.

The other two functions, certifying and encrypting, are **not** fungible. The exact key you use is
critical, and a different subkey will not work the same. This makes them much more important, and
much more sensitive. Transitioning between them is painful and best avoided. They often have to be
shared across devices, and should be locked with unique passwords to stop mistakes or malicious
attacks.

## Omit Needless Keys

The default behavior of GnuPG generates a primary key capable of certifying and signing, and a
subkey capable of encryption. I'm here to tell you that is stupid: you should never be signing
anything with your precious certifying primary key when you could be using a fungible signing-only
subkey, and you shouldn't generate encryption keys until you actually have a use for them in mind:
it's not worth the hassle.

Here's what I recommend putting in your configuration file:

``` text
default-new-key-algo ed25519/cert
```

That will change the default to generate a single primary key capable only of certification. You are
then free to make new subkeys as you deem useful, generally with only one function each.

## Passwords

As always, the trick is to keep as many of your passwords as possible in a password manager or other
form of encrypted state, then focus on memorizing only what you need to unlock the rest. If password
A can be used to access password B, don't bother memorizing password B.

Most of your passwords should be completely random. The ones you need to memorize should instead use
[diceware][1]. Keep the number you need to remember as low as possible (single digits), and drill
yourself on them regularly: I test my memory of those passwords monthly at minimum, halving the
period each time I get it wrong and doubling it each time I get it right.

## Expiration

**Every single key should have an expiration date, especially primary keys.** If this sounds
excessive, it is because you misunderstand the meaning of expiration.

An expired key should not be considered no longer valid: that is what revocation is for. Instead,
an expired key should be considered **outdated**, and in need of a refresh. Unless you forget (do
set reminders) or die, your key should not become outdated: you can simply take the primary key and
extend the expiration date.

Expiration dates are for the copies *everyone else* has: when you make changes to your key, others
do not magically find those changes. An expiration date is a way to inform others that they need
to get a newer version, in case something changed. Without one, an old copy of your key could be
floating around somewhere causing confusion indefinitely: with one, you have a cap on the amount of
time it takes anyone using your key to see changes.

I set expiration dates for keys based on when I expect an important change to happen (if I'm making
a signing key for a computer I expect to stop using in a few months, I'm going to set it to expire
around then).

The vast majority of keys, of course, are intended for indefinite use without foreseeable changes.
I generally set them to expire two years in the future, and set annual reminders to renew their
expiration date each year. This allows a lot of cushion in case I am busy around then, and ensures
anyone with my key has at least a year before they are forced to check for updates.

If finding all the keys on all your devices sounds like a hassle, remember that you don't need the
*private* keys to be renewed: all you need is the primary public key and private key. Whenever you
add a copy of your public key somewhere you control (like a GitLab account, for instance), add a
note to your renewal reminder that it'll need the fresh copy. In practice, this should take around
ten minutes at worst even if you have a lot of places to update.

## Revocation

Revocation is possibly the most misunderstood part of the entire standard: even [GitHub][2], one of
the most prominent users of GPG keys anywhere, only recently fixed their interpretation of it.

Revocation is functionally similar to expiration, except it cannot be reversed. The meaning is quite
different, however: while expiration indicates a key should be updated, revocation means a key
should not be used again. Key revocation includes a reason, which is **extremely important**: unless
it is revoked due to compromise, **the key should still be considered trustworthy**. A signature
made with a key revoked due to no longer being used is a **valid** signature. Sure, it should be
considered suspicious if the signature is newer than the revocation, but if the key was being used
maliciously it'd be revoked as compromised.

**Any key you do not intend to renew should be revoked.** If you're never going to use a key again,
revoke it and say so. If you're transitioning to a new key, revoke it and put the fingerprint (or
the authoritative source, if you prefer) of the replacement in the revocation comment. It does
not matter if it has already expired: when someone with an old copy of your key gets the current
version, they need to understand how to proceed. If the latest version is also expired, all they can
tell is that you've forgotten about it.

## The Most Important Feature No One Uses

Whether you use GnuPG as a tool or a toy is determined primarily by whether anyone else actually has
a current version of your key. Without that, it is almost entirely useless except as a particularly
convoluted approach to encryption.

Over the years, many people have worked tirelessly to make sharing keys more complicated and
difficult than it should be, and they've been broadly successful. Humor me for a moment, and forget
about public keyservers. Forget about the distributed keypools, forget about TOFU, forget about the
big complicated programs people have made for this.

Now, look at your key's preferences. [You see that option to set a "preferred keyserver"][3]? That
is one of the most important and neglected parts of the entire OpenPGP specification.

Set it to the URL where someone can get your key. This will become the One True Key, the canonical,
authoritative, ultimate arbiter of what your public key consists of. Every time anything about your
public key is changed, you will update this. It will contain every single element you consider part
of your key, without exceptions. Contrary to the name, **it does not have to be a keyserver**. In
fact, I recommend against it! Instead, simply set it to the URL of your exported public key. I host
my keys named by fingerprint at the `openpgpkey` subdomain of my personal domain, accessible over
direct HTTPS, secured by Let's Encrypt. That subdomain is also used for WKD, which I'll get to in a
bit.

### Finding your key, given a key

Because you set the preferred keyserver field, anyone who has an old copy of your key can trivially
get the newest copy, complete with revocations, additions, transitions, etcetera. In fact, GnuPG can
do it for them, if they set `--keyserver-options honor-keyserver-url`!

No matter how anyone actually gets your key, once they have it, they'll be able to use this source
in the future. All other sources are merely backups for this one. Even if you forget to update other
copies, they'll still point here, and that's all they really have to do.

### Finding your key, given a signature

We're not done yet: when you sign something (like a Git commit), you are doing so to make sure
others can verify it. If they can't, it's just [theater][4]. So you need to make sure that's all
they need.

Thankfully, GnuPG already has solutions for this. In order of precedence:

#### 1. `--include-key-block`

This configuration causes every signature you make to include a subset of your key. This is
exceptionally inefficient given how big these keys tend to get, and I recommend against it. It
strips key signatures, so the verifier can't really tell how trustworthy you are using the Web
of Trust that underpins PGP. The only real merit it has is allowing the verifier to use other
approaches, such as the preferred keyserver URL, to fetch the rest of the key. Speaking of which…

#### 2. `--sig-keyserver-url`

Welcome to one of the runners-up for Most Important Feature No One Uses. For the low price of a
few bytes, every signature you make can contain the definitive source of your *entire* public key,
complete with all the key signatures from others, allowing the verifier to actually \*gasp\* verify
the signature.

Because I have this in my configuration file, my signatures carry actual value. When someone pulls
a Git repository and runs `git log --show-signature`, assuming they have GnuPG set to auto-retrieve
keys, **Git will automatically fetch my current key and validate my commits according to the trust
system of the local keyring**.

In fact, as a demonstration of how powerful this is, I've signed this post using my default
settings and put the signature in a comment. Assuming you have a copy of GnuPG 2.3.6 with a default
configuration in your path, you can pass the plain text content of this post into the following
POSIX shell command and watch it automatically retrieve and evaluate my key to verify the signature.

``` shell
gpg --auto-key-retrieve --keyserver-options honor-keyserver-url --verify
```

Yes, that can be used as a "web bug". I could also embed an image in this post and accomplish the
exact same thing using your web browser, so I don't think that's a particularly serious problem.

#### 3. `--sender`

This embeds one of your UIDs into the signature. It's a poor substitute for a URL in my mind, as it
passes the buck to the section below for key retrieval. Nevertheless, you might find it useful to
specify a specific UID for some reason anyway. Keep in mind, however, that each signing key is tied
to *every* UID of the primary key, so this doesn't actually mean much.

#### 4. Nothing

With default signing options, you're left with just the fingerprint used to sign: see two sections
down for how the verifier can proceed from there.

### Finding your key, given a user ID or email

If you have your own domain, and your primary UID is hosted on that domain, this is quite
straightforward: use Web Key Directory and host a minimal subset of your key accordingly. If anyone
has your email, they can then get that subset. From that subset, they can pull the full key from the
preferred keyserver URL at their discretion.

You could also configure a PGP CERT record to point directly to your canonical key file, thus saving
them the trouble.

If your primary UID can't be used with WKD, you're somewhat out of luck: pray they check a keyserver
that has some form of your key floating around. If they do, they'll be able to fetch the latest
version in the same manner.

### Finding your key, given a fingerprint

Ideally, this never comes up: the main reason it would is if someone gets a public key you've signed
and wants to know who signed it ([a scenario rejected by GnuPG developers as unreasonable][5]).
As with UIDs on domains outside your control, you just have to hope they check a keyserver you've
uploaded a copy to.

---

I hope this helps others get more use out of GnuPG, which has gathered an undeserved reputation for
being obsolete or unusable. I read a lot of guides on how to use GPG over time, but I can't recall
almost any of them covering the points I have here. A lot of people report problems that can be
solved using these principles, and I hope these options become less obscure in the future.

[1]: https://en.wikipedia.org/wiki/Diceware
[2]: https://github.blog/changelog/2022-05-31-improved-verification-of-historic-git-commit-signatures
[3]: https://datatracker.ietf.org/doc/html/rfc4880#section-5.2.3.18
[4]: https://xkcd.com/1181/
[5]: https://dev.gnupg.org/T457


<!-- vim: set ft=markdown : -->
