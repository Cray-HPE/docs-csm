# Update the Privacy Settings for Gitea Configuration Content Repositories

Change the visibility of Gitea configuration content repositories from public to private. All Cray-provided repositories are created as private by default.

## Procedure

1. Log in to the Version Control Service \(VCS\) as the crayvcs user.

   Use the following URL to access the VCS web interface:

   ```bash
   https://vcs.SYSTEM-NAME.DOMAIN-NAME
   ```

2. Navigate to the cray organization.

   ```bash
   https://vcs.SYSTEM-NAME.DOMAIN-NAME/vcs/cray
   ```

3. Select the repository title for each repository listed on the page.

   ![Gitea Repositories](../../img/operations/gitea_repositories.png)

4. Click the **Settings** button in the repository header section.

   ![Gitea Repository Settings](../../img/operations/gitea_repository_settings.png)

5. Update the visibility settings for the repository.

   ![Gitea Repository Visibility](../../img/operations/gitea_repository_visibility.png)

   1. Click the **Visibility** check box to make the repository private.

   2. Click the **Update Settings** button to save the change for the repository.

