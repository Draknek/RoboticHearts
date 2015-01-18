#!/bin/bash

for size in 96 144
do
	topleft_outer=$(($size / 48))
	bottomright_outer=$(($size - $topleft_outer - 1))
	
	topleft=$(($topleft_outer * 2))
	bottomright=$(($size - $topleft - 1))
	
	radius_outer=$(($size / 12))
	radius=$(($radius_outer - topleft_outer))
	
	border_color='#ff3265'
	
	input=../ios/thumb${size}.png
	output=thumb${size}.png
	echo "Converting $input"
	inner_roundrectangle="roundrectangle $topleft,$topleft $bottomright,$bottomright $radius,$radius"
	outer_roundrectangle="roundrectangle $topleft_outer,$topleft_outer $bottomright_outer,$bottomright_outer $radius_outer,$radius_outer"
	convert -size ${size}x${size} \
		\( xc:none -fill white -draw "$inner_roundrectangle" \) "$input" -compose SrcIn -composite \
		\( xc:none -fill "$border_color" -draw "$outer_roundrectangle" \) -compose DstOver -composite \
		"$output"
done