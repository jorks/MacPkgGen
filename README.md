# Git Package Builder

This solution enables you to manage the end-to-end process of building macOS packages with git source control and GitHub Workflows.

Features: 

- GitHub Workflow templates
	- Build, sign and notarize a macOS package using GitHub runners
	- Create a pre-release package for testing
	- Create a GitHub Release

- Scripts to support the workflow
	- `build_package.sh` - builds, signs and notarizes a package 
	- `create_project.sh` - initiate a new git project using this repository as a template
	- `install_munkipkg.sh` - install the munkipkg dependency
	- `pre-commit` - a git Hook to ensure git compatibility

## Create a new Project

This solution comes with a guided install script. On your local machine `cd` into your Packages directory and run:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jorks/Jamf-Prestage-Assets/HEAD/helpers/create_project.sh)"
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

1. Update the `build-info` file with your package details
2. Add Folders and Files to the `payload` directory and set ownership and permissions as desired
3. Add any required `preinstall` and `postinstall` scripts to the `scripts` directory
4. `git commit` the changes which will trigger the `pre-commit` git hook script
5. `git push` and head over to GitHub and kick off the workflow in the actions tab.

You may also wish to update some of the text or triggers in the `.git/workflow` files.

## Setting Up the GitHub repository

This project requires some specific GitHub settings and secrets to be configured in the repository.

**Enable Write Permissions:**

`GITHUB_TOKEN` - this is an automatically created token. You will need to enable write permissions for this token:
Go to Settings > Actions > General and set the "Workflow permissions" to "Read and write permissions".

**Required for Package Signing:**

| Key                           | Value Description                                                                                                        |
|-------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| PKG_CERTIFICATES_P12          | A base64 output of the developer certificate P12 file.<br>Use this command: `base64 -i <certificate_name>.p12 \| pbcopy` |
| PKG_CERTIFICATES_P12_PASSWORD | This is the password used to decrypt the developer certificate P12 file                                                  |
| PKG_KEYCHAIN_PASSWORD         | Any randomly generated password.                                                                                         |

**Required for Notarization:**

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