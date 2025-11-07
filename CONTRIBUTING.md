# Contributing Guide

How to set up, code, test, review, and release so contributions meet our Definition of Done.

## Code of Conduct

When a contributor introduces a bug into the project, it is their responsibility to fix it. You cannot approve your own merge request.

## Getting Started

To get started, you first need Godot v4.5. Then you need to load in project.godot from GitHub, which should load the project. Once you have the project loaded, check the Godot plugins and make sure that LimboAI v1.5.1 is installed and enabled in the project settings. To run the app, make sure that layer\_manager.tscn is the home scene, and click Run in the top right. 

## Branching & Workflow

During each sprint, each team member should make a branch to hold their sprint contributions (named in lowercase and underscores). After each sprint, each contributor should merge their branch into main to provide a universal baseline for the next sprint.

## Issues & Planning

We utilize Trello instead of issues. There is a column for bug issues to be placed upon, and then they will be fixed by the developer of the respective area(i.e, an enemy bug will be fixed by the enemy AI developer)

## Commit Messages

Commit messages should be descriptive of the main topic of the change, while the description should include possible problems or next steps for the branch.   
Some example commits:   
[https://github.com/TheMoneyRaider/Game-Dev-Team-1/commit/144975f8bcef618a702b95f865a4af158f24365e](https://github.com/TheMoneyRaider/Game-Dev-Team-1/commit/144975f8bcef618a702b95f865a4af158f24365e)  
[https://github.com/TheMoneyRaider/Game-Dev-Team-1/commit/45ab9fd2edaeab4c00cb7f4656b07e5896bdaf6c](https://github.com/TheMoneyRaider/Game-Dev-Team-1/commit/45ab9fd2edaeab4c00cb7f4656b07e5896bdaf6c)

## Code Style, Linting & Formatting

Naming conventions, Snake Case  
New files should follow standard Godot organization schemes, i.e scripts go in the “scripts” folder. Subdivisions of these folders are encouraged. If subdivisions are made, it is encouraged to organize the files within the folder after the new folders are made. 

## Testing

Due to the way that Godot works, we don’t have any automated tests, though whenever we merge branches into main, we make sure to manually test and ensure that the code still works.

## Pull Requests & Reviews

In the case of a merge conflict, the person putting in the pull request must provide a way to resolve the merge conflict, and someone other than the requester must check and approve of the pull request.

## CI/CD

Due to the way Godot Works, we don’t have any CI/CD pipelines. Therefore, we just push to GitHub. We manually ensure that the code works regularly, but we haven’t found a GitHub tool to test Godot code automatically.

## Security & Secrets

Due to the nature of our project, we don’t have any vulnerable information in our code.

## Documentation Expectations

We try to self-police to make sure each other uses informative commit messages, but due to the nature of the project, we don’t need comprehensive docs or refs, and we use Discord to keep a semi-detailed changelog for our own reference.

## Release Process

We have a plan to release our project on Steam once we have a sufficiently functional game. We don’t have a planned versioning scheme aside from the fact that we plan to label it as a beta version on account of the fact that we only plan to make one “stage” out of the originally planned 4\.

## Support & Contact

We are considering making a team email account that we can attach to the project so that players have an impersonal way of getting in contact with us to let us know about major bugs and other issues. Once this is in place, we will monitor the inbox weekly at a minimum.
