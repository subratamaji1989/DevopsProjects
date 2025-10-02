## **Introduction to Version Control -- GIT**

## **What is Git?**
Git is a distributed version control system (DVCS) that allows multiple people to work on the same project while keeping track of changes. It enables teams to collaborate efficiently, track modifications, and revert to previous versions when needed.

## **What is GitHub and GitLab?**
**GitHub** and **GitLab** are cloud-based Git repository hosting services that provide additional features like pull requests, issue tracking, and CI/CD pipelines. 

- **GitHub** is widely used in open-source communities and enterprise software development.
- **GitLab** provides built-in DevOps features like CI/CD pipelines and project management tools.


### **1. Set Up the Environment**
## Installing Git

### Windows
1. Download Git from (https://git-scm.com/downloads/win).
2. Run the installer and follow the setup wizard.
3. Verify installation by running:
   ```bash
   git --version
   ```

### macOS
1. Install Git using Homebrew:
   ```bash
   brew install git
   ```
2. Verify installation:
   ```bash
   git --version
   ```

### Linux
1. Install Git using the package manager:
   ```bash
   sudo apt install git   # Debian-based systems
   sudo yum install git   # RHEL-based systems
   ```
2. Verify installation:
   ```bash
   git --version
   ```

## Setting Up GitHub and GitLab Accounts

### GitHub
1. Go to [GitHub](https://github.com/) and sign up.
2. Confirm your email address.
3. Set up SSH authentication or a Personal Access Token (PAT) for secure access.

### GitLab
1. Go to [GitLab](https://gitlab.com/) and create an account.
2. Confirm your email address.
3. Create a new repository or fork an existing one.
4. Set up SSH authentication for GitLab:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your.email@example.com"
   ssh-add ~/.ssh/id_rsa
   ```

### **2. Clone and Configure Git**
- **Fork the Repository**: Fork the provided GitHub and GitLab repositories to your own account.
- **Clone the Repository**: Clone the forked repository to your local machine.

```bash
git clone https://github.com/subratamaji1989/DevopsProjects.git
```

- **Configure Git**: Set up your username and email.

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### **3. Create a Feature Branch and Make Changes**
- Create a new branch for feature.

```bash
git checkout -b feature/my-feature
```

- **Make changes and check the differences before staging:**

```bash
git diff
```

- **Stage and commit your changes:**

```bash
git add .
git commit -m "Added new feature: my-feature-name"
```

- **Modify the last commit if needed:**

```bash
git commit --amend -m "Updated commit message with additional changes"
```

### **4. Push Your Changes and Create a Pull Request (PR)**
- **Verify the current branch (HEAD position):**

```bash
git rev-parse --abbrev-ref HEAD
```

- **Push your branch to the remote repository:**

```bash
git push origin feature/your-feature-name
```

- **Create a Pull Request (PR) on GitHub and a Merge Request (MR) on GitLab.**
- **Follow best practices for writing PR descriptions and handling reviews.**

### **5. Resolve Merge Conflicts**
- **Check the current remote repository (origin):**

```bash
git remote -v
```

- Simulate a merge conflict by modifying the same file from another GitHub account.
- Pull the latest changes and merge.

```bash
git checkout main
git pull origin main
git checkout feature/your-feature-name
git merge main
```

- Resolve conflicts manually and commit.

```bash
git add .
git commit -m "Resolved merge conflict in your-feature-name"
```

### **6. Review and Merge**
- **Use your second GitHub account to review and approve the PR.**
- **Perform the same review and merge process on GitLab.**
- Merge the PR once approved.

### **7. Clean Up**
- **Delete your feature branch locally and remotely.**

```bash
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```

### **8. Viewing Commit Logs**
- View commit history in different formats:

```bash
git log --oneline
git log --pretty=format:"%h - %an, %ar : %s"
git log --stat
```

- Search for specific commit messages:

```bash
git log --grep="fix bug"
```


### Summary of Git Commands Used

- **git init**: Initializes a new Git repository.
- **git clone**: Copies a remote repository to your local machine.
- **git config**: Configures user details like name and email.
- **git checkout -b <branch>**: Creates and switches to a new branch.
- **git add .**: Stages all changes for commit.
- **git commit -m "message"**: Saves changes to the repository with a message.
- **git push origin <branch>**: Pushes local changes to a remote repository.
- **git pull origin main**: Fetches and merges the latest changes from the main branch.
- **git merge <branch>**: Merges another branch into the current branch.
- **git log**: Displays the commit history.
- **git diff**: Shows changes between commits, branches, or the working directory and staging area.
- **git branch -d <branch>**: Deletes a local branch.
- **git push origin --delete <branch>**: Deletes a remote branch.
- **HEAD**: Represents the current branch or commit you are working on.
- **origin**: The default name for the remote repository from which the local repository was cloned.


---

## Advanced Git Concepts

### 1. Amending Commits

**Theory:** The `git commit --amend` command modifies the most recent commit.

**Use Cases:**

*   Fix typos in commit messages.
*   Add missed changes to the commit.

**Visual Workflow:**

```
A[Original Commit] --> B[Stage Changes]
B --> C[git commit --amend]
C --> D[Updated Commit]

```
**Example:**
```
git add .
git commit --amend -m "Add login validation with updated test cases"
```

### 2. Rewriting History with Interactive Rebase

**Theory:** Interactive rebasing (`git rebase -i`) allows you to:

*   Squash commits: Combine small commits into one.
*   Reword messages: Clarify commit descriptions.
*   Drop commits: Remove accidental changes.

**Visual Workflow:**

```
A[Commit 1] --> B[Commit 2]
B --> C[Commit 3]
D[Rebase Command] --> E[Squash Commits 2 & 3]
E --> F[Final Commit]
```
**Steps:**
```
git rebase -i HEAD~3
```
Follow prompts to squash, reword, or drop commits
```git rebase --continue```


### 3. Tagging Releases

**Theory:** Tags mark releases in history.

*   Lightweight Tags: Point directly to commits.
*   Annotated Tags: Include metadata (author, message).

**Visual Comparison:**

```
title Tag Types
"Lightweight (v1.0.0)" : 50
"Annotated (v1.1.0)" : 50
```

**Steps:**
```
git tag v1.0.0 # Lightweight
git tag -a v1.1.0 -m "Stable release with auth fixes"
git push origin --tags
```


### 4. Syncing with Upstream

**Theory:** When collaborating:

*   `origin`: Your forked repository.
*   `upstream`: The original repository.

**Visual Workflow:**

```
A[Original Repo] -->|upstream| B[Your Fork]
B -->|origin| C[Local Machine]
C -->|git fetch upstream| A
```


**Steps:**
```
git remote add upstream https://github.com/organisation/repo.git
git fetch upstream
git merge upstream/main
```


### 5. Stashing and Cherry-Picking

**Theory:**

*   Stashing: Temporarily saves uncommitted changes.
*   Cherry-Picking: Applies a specific commit from another branch.

**Visual Workflow:**

```
participant FeatureBranch
participant HotfixBranch
FeatureBranch->>HotfixBranch: git cherry-pick xyz256
HotfixBranch->>FeatureBranch: Apply commit
```


**Steps:**

```
git stash
git checkout hotfix
git cherry-pick xyz256
git stash pop
```


### 6. Rebasing vs. Merging

**Theory:**

*   Rebasing: Linear history (ideal for feature branches).
*   Merging: Preserves branch history.

**Comparison:**

```
A[Rebase] -->|Linear History| B[Clean Timeline]
C[Merge] -->|Merge Commits| D[Branch Con]
```


**Rebase Workflow:**
```
git fetch origin
git rebase origin/main
git push --force
```


### 7. Undoing Changes

**Theory:**

*   `git reset`: Discard commits (use cautiously!).
*   `git revert`: Safely undo commits.

**Comparison Table:**
```
| Command        | Use Case                        | Risk Level |
|----------------|---------------------------------|------------|
| `reset --soft` | Uncommit but keep changes       | Low        |
| `reset --hard` | Discard changes permanently     | High       |
| `revert`       | Create undo commit              | None       |
```
**Example:**
```
git reset --soft HEAD~1
git revert xyz256
```

### 8. Git Branching Strategies

**Theory:** Branching strategies are workflows for managing code development and collaboration using Git branches. Choosing the right strategy depends on your team size, release frequency, and project complexity.  Common strategies include:

*   **Gitflow:** A strict model designed for scheduled releases. It uses feature branches, release branches, and hotfix branches, in addition to the main and develop branches.
*   **GitHub Flow:** A simpler workflow where everything in the `main` branch is deployable. Feature branches are created off main and merged back in after review.
*   **Trunk-Based Development:** Developers commit directly to the main branch, keeping it continuously deployable. Feature toggles are often used to manage incomplete features.
