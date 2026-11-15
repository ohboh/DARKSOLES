shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_nearest;
uniform float parry = 0.0;
const float b[16]=float[16](0.,8.,2.,10.,12.,4.,14.,6.,3.,11.,1.,9.,15.,7.,13.,5.);
void fragment(){
	vec3 c=texture(screen,SCREEN_UV).rgb;
	vec2 pos=SCREEN_UV*2.-1.; vec2 res=1./SCREEN_PIXEL_SIZE;
	float radius=length((SCREEN_UV-vec2(.5,.55))*res)/(res.x*.5);
	float shade=1.-smoothstep(.78,1.45,radius)*.5;
	float luminance=dot(c,vec3(.30,.59,.11));
	bool red=c.r-max(c.g,c.b)>.21;
	float value=pow(clamp(red?c.r:luminance,0.,1.),1.27)*shade+parry*.17;
	vec2 p=floor(FRAGCOORD.xy);
	float ordered=(b[int(mod(p.y,4.))*4+int(mod(p.x,4.))]+.5)/16.;
	float grit=fract(52.9829189*fract(dot(p,vec2(.06711056,.00583715))));
	float threshold=ordered+(grit-.5)*.035;
	vec3 ink=vec3(0.);
	vec3 chalk=vec3(1.);
	COLOR=vec4(value*.78>threshold?(red?vec3(1.,0.,0.):chalk):ink,1.);
}
