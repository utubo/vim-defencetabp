# vim-defencetabp

Defence your tabpages!
![image](https://github.com/user-attachments/assets/34e539a9-e803-498a-be7c-86c70d0bb43f)

## Get start

### Requirements

Vim 9.1 and +tabpanel

### Installation

Add rtp to vim-defencetabp.  
e.g.
```bash
mkdir -p ~/vim/pack/local/start
cd ~/vim/pack/local/start
git clone https://github.com/utubo/vim-defencetabp.git
```

You can call this `Start()` to start the game.
```vim
:call defencetabp#Start()
```

## Rule


`V` ... You
`A` ... Enemey
`-` ... Sheild

Enemies shot to close tabpages.  
Shoot all enemies to save your tabpages.  
If the last tabpage is closed, quit vim.

## Mappings

- `<Space>` ... Shot
- `h` ...  Move left
- `l` ...  Move right
- `q` or `<Esc>` ... Quit this game.

## License

NYSL 0.9982
https://www.kmonos.net/nysl/
