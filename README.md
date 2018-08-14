# Git CD Flow 
## An almost decent git process for our needs
git-cdflow is the main tool we use in Etiqa to manage our git repositories. More than a tool it is an opinionated
and formalized process designed to make our release process less error-prone. 

We think that if not the tool at least the idea, could be useful to someone else
with similar needs to ours, so we decided to share it.

## The basic problem
Before going deeper into the tool we should give you a little bit of contest. Git is a relatively recent tool in the enterprise world to manage source control. Probably in the last 15 years or so you had experience with subversion or even CVS and let's be honest, Git has been fresh air for the code management with its decentralized and local approach. 
However, as usual, with great power comes great responsibility (cit), so we decided we needed a process in order to keep some order in the 
code organization.

As any decent team of programmers, we are a team of lazy guys, more interested in coding than in processes, ready to
embrace the first good-enough process out there, and git-flow had all papers in order to be the great tool we were
looking for:

* Easy to understand
* Easy to implement
* Enough formalized to keep branches on track

## The real problems
But, as you can imagine, in the end it was not a good fit for us. I want to stress it again: *for us*. Git Flow is a great
tool, so if it's working for you, keep on it! no doubts!

So, what are these problems we are talking about? 

The first one is not a problem at all with the tool but I would label it under the label "client madness". 
The approach develop/release/master/hotfix was not "sophisticated" enough to handle our clients. 
Most of the time we work on multiple branches at the same time, one release for "hard" development, one deployed on qa1 with 
some set of features, another one in qa2 with a different set of features, a release in uat1 parked for months waiting
for a regulatory review and of course another one in production ready to come up with some 
super-urgent-bug-no-one-noticed-it-before. As you can imagine the clean develop->release->master timeline was completely no-sense for us,
spending more time to workaround the git flow process than to embrace it. At the end what we needed was a complex three with many branches,
all first-class citizen in the tree.

The second problem we have around our quality process and continuous delivery process. 
Sometimes we introduce some new functionalities but we are not sure we like it and we want to put it in production, 
so we keep our code in a feature branch and we test it. Let's say that we like the functionality and the QA validated it? What should we do?
Merge it back in the release/master branch? In Etiqa we have a simple rule: if we test a release and QA validate it (QA pass) when we rebuild
it is not anymore QA pass status, even without code changes. It could sound a little bit dramatic, but for our experience, in the build process, there are many things that can go wrong: dependencies set as "greater-than" instead of exact, cache invalidation, third parties/upstream updates and so on. Long story short: if we test a release branch and validate it we want to go live with it.

Third problem: if a programmer can forget to do a merge he/she will forget it. 
Let's imagine this simple but real-world scenario: we have an upcoming release in a week, let's say release 10 and another release, let's say 11,
planned for the next month. Our diligent developer working on release 11 should daily merge release 10 into release 11 but what happens when then the client asks for some unplanned but very important functionality that cannot wait for release 11 and a new release 10.5 is created? Who wants to bet that if the communication process is less than perfect,
next month there will be a release 11 in production without the features of the release 10.5?

## The (it-works-for-us) solution
First of all, we need to attach some metainformation to git to keep track of real tree structure we want to use:

The release start command let you create a new release branch setting a parent branch from a menu
```bash
git cdflow release start 11
```
Under the hood, git-notes is used. A note with the following text is added: *[release/v10.0.0 -> release/v11.0.0]* 

Now that we have some metainformation added we want a handy way to retrieve it:
```bash
git cdflow parent show
```

But most importantly, we want to simplify the process of merge the changes of the upstream branch:
```bash
git cdflow parent pull
```

Changing the structure of the tree should be easy enough:
```bash
git cdflow parent set release/v10.5.0
```
And of course the next parent pull will merge using the right branch, 10.5 instead of 10.

It's time to do some experiments with our code
```bash
git cdflow feature start my-cutting-edge-feature
```

And the new *feature/my-cutting-edge-feature* has been created

Hey, I need some help here, but the code is not ready to be deployed... let publish it but keep private, and since our Jenkins
multipipeline is configured to build all features and release branch but nothing with private in front of it we can run:

```bash
git cdflow feature private
```

It's time to deploy some QA server... make it public
```bash
git cdflow feature public
```

Wow... it was a success, stakeholders decided they want my cutting-edge feature in production, and not anymore release 10.5
Let's checkout release 11 and change the parent
```bash
git cdflow release checkout 11
git cdflow parent set feature/my-cutting-edge-feature
``` 

Uhm, the situation is becoming a little hot here, let's show the tree
```bash
git cdflow tree show
```

```bash
+-release/v10.0.0
  |
  +-feature/my-useless-feature
  |
  +-release/v10.5.0
    |
    +-feature/my-cutting-edge-feature
      |
      +-release/v11.0.0
        |
        +-release/v12.0.0      
```

Let's check if everyone did homework and parent pull
```bash
git cdflow tree status
```

Ooopsss

```bash
Family tree missing merges:
release/v11.0.0	not merged in release/v12.0.0
release/v10.0.0 not merged in feature/my-useless-feature
```