shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform int omen=0;
void fragment(){
	vec2 p=UV*2.-1.;
	float fade=(1.-smoothstep(.55,1.,abs(p.x)))*(1.-smoothstep(.65,1.,abs(p.y)));
	float strength=0.;
	if(omen==2){
		// Narrow, irregular fingers of shadow reach out onto the approach.
		float fingers=pow(.5+.5*cos(p.x*13.+1.5*sin(p.y*3.)),3.);
		strength=fade*(.25+.7*fingers)*(.93+.07*sin(TIME*1.7));
		ALBEDO=vec3(0.);
	}else if(omen==1){
		float pool=exp(-4.*dot(p,p));
		strength=pool*(.21+.035*sin(TIME*8.)*sin(TIME*5.));
		ALBEDO=vec3(1.);
	}else{
		for(int i=0;i<3;i++){
			vec2 q=p-vec2(sin(float(i)*5.1)*.38,cos(float(i)*3.5)*.29);
			float glint=exp(-abs(q.x)*42.-abs(q.y)*9.)+exp(-abs(q.x)*10.-abs(q.y)*43.);
			strength+=glint*(.38+.19*sin(TIME*2.7+float(i)*2.));
		}
		strength+=.11*exp(-5.*dot(p,p));
		ALBEDO=vec3(1.);
	}
	ALPHA=clamp(strength,0.,.88);
}
