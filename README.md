my custom AUR repo

for Paru:
```bash
mkdir -p ~/.config/paru

cat > ~/.config/paru/paru.config << EOF
[kappa-repo]
Url = https://github.com/zerobikappa/kappa-repo-pkgbuild.git
EOF

paru -Sy
```
