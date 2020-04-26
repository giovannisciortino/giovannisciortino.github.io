---
title:  "Use GitHub Actions to create Jekyll post from GitHub issue"
tags: [github actions,jekyll]
---
This post describe a GitHub Actions workflow that allow to create new post on a Jekyll web site contained in a GitHub repository using the issue editor of GitHub website.

GitHub Actions [1] makes it easy to automate all your software workflows, it build, test, and deploy your code right from GitHub. 
Jekyll [2] is a simple, blog-aware, static site generator perfect for personal, project, or organization sites. 

The article [3], describing the disadvantages of static site generator software compared to CMS software, includes among them the following "Publishing the site requires tools and code on your computer". 
The GitHub Actions workflow described in this post allows to mitigate this problem. This workflow allows to use the web interface of GitHub to create Jekyll posts exploiting the "MarkDown editor" and "check spelling" features contained in the issue editor of GitHub web site without require any tool installed.

The automation described in this post is contained in three files:

1. A github issue template [4] containing a template of a new jekyll post file
2. A github issue configuration file [5] that allow to create also github issue not respecting the template described in 1.
3. A Github Workflow [6]

The GitHub workflow has been reported also below in order to describe its main components:

{% highlight YAML linenos %}
name: A workflow to create a jekyll post from github issue
on:
  issue_comment:
    types: [created]
jobs:
  build:
    name: A job to create a jekyll post from github issue
    runs-on: ubuntu-latest
    if: github.event.comment.body == 'publish'
    steps:
      - name: Checkout master branch
        uses: actions/checkout@master

      - name: Create jekyll post file
        if: success() && github.event.issue.user.login == env.GITHUB_ACCOUNT_JEKYLL_OWNER
        run: |
          cat << 'EOF' > $POST_DIRECTORY/${{ github.event.issue.title }}
          ${{ github.event.issue.body }}
          EOF
        env:
          GITHUB_ACCOUNT_JEKYLL_OWNER: 'giovannisciortino'
          POST_DIRECTORY: '_posts'

      - name: Commit files
        if: success()
        run: |
          git config --local user.name "$GIT_USER_NAME"
          git config --local user.email "$GIT_USER_EMAIL"
          git add --all
          # commit only if there are changes
          if [[ `git status --porcelain` ]]; then
            git commit -m "$DEFAULT_COMMIT_MESSAGE" -a
          fi
        env:
          GIT_USER_NAME: 'Giovanni Sciortino'
          GIT_USER_EMAIL: 'giovannibattistasciortino@gmail.com'
          DEFAULT_COMMIT_MESSAGE: 'New jekyll post create from github issue'

      - name: Push changes
        if: success()
        uses: ad-m/github-push-action@master
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
{% endhighlight %}

This GitHub workflow contains the following main elements:
- it contains the trigger executing it (line 3-4). It's triggered when a new comment is added to a github issue
- it execute the four steps of the job contained in the workflow when someone write the comment "publish" in the GitHub issue (line 9)
- The first step clone the repository containing the Jekyll git repository in a ubuntu docker container (line 11-12)
- The second step verify that the author of the command publish is the owner of the GitHub repository and create the Jekyll post reading the content from the title and the first message of the github issue (line 14-22)
- The third step create a new commit using the file modified in the second step (line 24-37)
- The forth sep push the new commit to GitHub (line 39-43)

These three files allow to implement the workflow described in this post.
The automation described in this post has been used to create this post itself, [7] is the GitHub issue used to create this post.

[1] https://github.com/features/actions

[2] https://jekyllrb.com/

[3] https://www.strattic.com/jekyll-hugo-wordpress-pros-cons-static-site-generators/

[4] https://github.com/giovannisciortino/giovannisciortino.github.io/blob/master/.github/ISSUE_TEMPLATE/jekill_post_new_template.md

[5] https://github.com/giovannisciortino/giovannisciortino.github.io/blob/master/.github/ISSUE_TEMPLATE/config.yml

[6] https://github.com/giovannisciortino/giovannisciortino.github.io/blob/master/.github/workflows/create_jekyll_post_from_issue.yamlhttps://raw.githubusercontent.com/giovannisciortino/giovannisciortino.github.io/master/.github/workflows/create_jekyll_post_from_issue.yaml

