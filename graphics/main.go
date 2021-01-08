package main

import (
	"fmt"
	"image/png"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	fnames, err := filepath.Glob("*.png")
	if err != nil {
		panic(err)
	}

	f, err := os.Create("../lib/pixels.lua")
	if err != nil {
		panic(err)
	}
	f.WriteString("local Pixels = {}\n")
	f.WriteString("local pixel_graphics = {\n")
	for _, fname := range fnames {
		f.WriteString(fmt.Sprintf("%s = {%s},\n",strings.TrimSuffix(fname,".png"),pixelToLua(fname)))
	}
	f.WriteString("}\n")
	f.WriteString(`
function Pixels.pixels(name)
	return pixel_graphics[name]
end

return Pixels
`)
}

func pixelToLua(fname string) (string) {
	f, err := os.Open(fname)
	if err != nil {
		panic(err)
	}
	img, err := png.Decode(f)
	if err != nil {
		panic(err)
	}

	current := ""
	for x := img.Bounds().Min.X; x <= img.Bounds().Max.X; x++ {
		for y := img.Bounds().Min.Y; y <= img.Bounds().Max.Y; y++ {
			c := img.At(x, y)
			a, b, e, d := c.RGBA()
			d = a + b + e + d
			if d > 0 {
				current += fmt.Sprintf("{%d,%d,15},", y+1, x+1) // row, col, intensity
			} 
		}
	}

	return current[:len(current)-1]
}
