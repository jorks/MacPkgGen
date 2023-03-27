# Mac Package Generator

[Mac Package Generator](https://github.com/jorks/MacPkgGen) streamlines the creation of macOS packages by leveraging GitHub Actions. With built-in git source control, this end-to-end solution automates the process of building, signing, and notarizing a macOS package into a GitHub Release. Creating a new package project is simple with the one-line "create project" script.

- Scripts to support the workflow
	- `create_project.sh` - initiate a new git project using this repository as a template
	- `build_package.sh` - builds, signs and notarizes a package 
	- `install_munkipkg.sh` - install the munkipkg dependency as required
	- `pre-commit` - a git Hook to ensure git compatibility via a BOM.txt file
	- `install_dependencies.sh` - run this script after you clone an existing project

## Create a new Project

This solution comes with a guided install script. On your local machine `cd` into a working directory for your packages and run:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jorks/MacPkgGen/main/helpers/create_project.sh)"
```

The script will:

- Prompt you for the name of your new package project
- Prompt you for the URL of the remote GitHub repository (optional)
- Install XCode Command Line Tools (if not installed)
- Clone this project and initiate a new git project
- Install Munki PKG in a tmp directory
- Create a new Munki PKG project
- Add a pre-commit git hook to the local git project
- If a remote URL is provided, push the initial commit

## Working with the project

This solution uses Munki PKG to do the heavy lifting in building the package. Please refer to [their guide](https://www.munki.org/munki-pkg/) for detailed instructions using Munki PKG. After creating a new project, you would typically:

**Setup the Package**

1. Update the `build-info` file with your package details
2. Add Folders and Files to the `payload` directory and set ownership and permissions as desired
3. Add any required `preinstall` and `postinstall` scripts to the `scripts` directory.

**Use git to commit and push your changes to GitHub**

1. `git add .` to add all the changes and new files
2. `git commit` the changes which will trigger the `pre-commit` git hook script
3. `git push` and head over to GitHub and kick off the workflow in the actions tab.

You may also wish to update some of the text or triggers in the `.git/workflow` files.

## Setting Up the GitHub repository

This project requires some specific GitHub settings and secrets to be configured in the repository.

**Enable Write Permissions:**

`GITHUB_TOKEN` - this is an automatically created token used in workflow files. You will need to enable write permissions for this token:

Go to Settings > Actions > General and set the "Workflow permissions" to "Read and write permissions".

**Secrets Required for Package Signing:**

| Key                           | Value Description                                                                                                        |
|-------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| PKG_CERTIFICATES_P12          | A base64 output of the developer certificate P12 file.<br>Use this command: `base64 -i <certificate_name>.p12 \| pbcopy` |
| PKG_CERTIFICATES_P12_PASSWORD | The password used to decrypt the developer certificate P12 file                                                          |
| PKG_KEYCHAIN_PASSWORD         | Any randomly generated password.                                                                                         |

**Secrets Required for Notarization:**

_Optional - if these are not configured your package will simply skip notarization._

| Key               | Value Description                                                               |
|-------------------|---------------------------------------------------------------------------------|
| NOTARIZE_APPLE_ID | Apple ID for the Apple Developer account to submit the package for notarization |
| NOTARIZE_PASSWORD | App Specific Password generated for this account at appleid.apple.com           |
| NOTARIZE_TEAM_ID  | The Team ID from the developer certificate.                                     |

## Triggering the Workflows

All the workflows are configured to run manually when you click "Run Workflow" via the GUI.
This is defined with `on: [workflow_dispatch]` in the workflow files.

You may wish to change this, please refer to the [GitHub documentation](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow).

## Cloning an Existing Project

When you clone an existing project you will need to run the `install_dependencies.sh` script. This will:

- Check for Xcode CLT and prompt you to install them if they are missing
- Install MunkiPKG
- Add the git pre-commit hook
- Sync the BOM file into the local git project.

