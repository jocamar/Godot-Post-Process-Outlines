shader_type spatial;
render_mode depth_draw_never, depth_test_disable, unshaded;

uniform float color_outline_scale = 2.0; // Size of color outlines
uniform float depth_outline_scale = 2.0; // Size of depth outlines
uniform float depth_threshold : hint_range(0,10) = 2.5; // Controls sensitivity to depth changes (lower values mean more outlines, but more artifacts too)
uniform float depth_multiplier = 1000.0; // Multiplier for depth values
uniform float edge_threshold : hint_range(0,1) = 0.04; // General threshold for values to be considered as edges
uniform float max_edge_alpha : hint_range(0,1) = 0.8; // Max edge alpha, lower values means edges blend more with background
uniform float edge_alpha_multiplier = 3.0; // General multiplier for edge alpha value, higher values mean harder edges

uniform vec4 edge_color : hint_color = vec4(0,0,0,1); // Outlines color
uniform sampler2D bgTex : hint_albedo; // BG texture

uniform bool depth_use_laplace = true; // Sets depth edges to use the laplace operator instead of sobel
uniform bool color_use_laplace = false; // Sets color edges to use the laplace operator instead of sobel
uniform bool use_bg_texture = false; // Sets shader to use render the BG behind the edges

varying mat4 CAMERA;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	CAMERA = CAMERA_MATRIX;
}

float getDepthVal(sampler2D depthTex, vec2 depthUV, mat4 invProjMat) {
	float depth = texture(depthTex, depthUV).r;
	return depth;
}

void fragment() {
	float halfScaleFloor_c = floor(color_outline_scale * 0.5);
	float halfScaleCeil_c = ceil(color_outline_scale * 0.5);
	float halfScaleFloor_d = floor(depth_outline_scale * 0.5);
	float halfScaleCeil_d = ceil(depth_outline_scale * 0.5);
	vec2 texelSize = vec2(1.0/VIEWPORT_SIZE.x, 1.0/VIEWPORT_SIZE.y);
	
	vec2 bottomLeftUV_c = SCREEN_UV - vec2(texelSize.x, texelSize.y) * halfScaleFloor_c;
	vec2 topRightUV_c = SCREEN_UV + vec2(texelSize.x, texelSize.y) * halfScaleCeil_c;
	vec2 topUV_c = SCREEN_UV + vec2(0.0, texelSize.y * halfScaleCeil_c);
	vec2 bottomUV_c = SCREEN_UV + vec2(0.0, -texelSize.y * halfScaleFloor_c);
	vec2 rightUV_c = SCREEN_UV + vec2(texelSize.x * halfScaleCeil_c, 0.0);
	vec2 leftUV_c = SCREEN_UV + vec2(-texelSize.x * halfScaleFloor_c, 0.0);
	vec2 bottomRightUV_c = SCREEN_UV + vec2(texelSize.x * halfScaleCeil_c, -texelSize.y * halfScaleFloor_c);
	vec2 topLeftUV_c = SCREEN_UV + vec2(-texelSize.x * halfScaleFloor_c, texelSize.y * halfScaleCeil_c);
	vec2 centerUV_c = SCREEN_UV;
	
	vec2 bottomLeftUV_d = SCREEN_UV - vec2(texelSize.x, texelSize.y) * halfScaleFloor_d;
	vec2 topRightUV_d = SCREEN_UV + vec2(texelSize.x, texelSize.y) * halfScaleCeil_d;
	vec2 topUV_d = SCREEN_UV + vec2(0.0, texelSize.y * halfScaleCeil_d);
	vec2 bottomUV_d = SCREEN_UV + vec2(0.0, -texelSize.y * halfScaleFloor_d);
	vec2 rightUV_d = SCREEN_UV + vec2(texelSize.x * halfScaleCeil_d, 0.0);
	vec2 leftUV_d = SCREEN_UV + vec2(-texelSize.x * halfScaleFloor_d, 0.0);
	vec2 bottomRightUV_d = SCREEN_UV + vec2(texelSize.x * halfScaleCeil_d, -texelSize.y * halfScaleFloor_d);
	vec2 topLeftUV_d = SCREEN_UV + vec2(-texelSize.x * halfScaleFloor_d, texelSize.y * halfScaleCeil_d);
	vec2 centerUV_d = SCREEN_UV;
	
	float d0 = getDepthVal(DEPTH_TEXTURE, topLeftUV_d, INV_PROJECTION_MATRIX);
	float d1 = getDepthVal(DEPTH_TEXTURE, topUV_d, INV_PROJECTION_MATRIX);
	float d2 = getDepthVal(DEPTH_TEXTURE, topRightUV_d, INV_PROJECTION_MATRIX);
	float d3 = getDepthVal(DEPTH_TEXTURE, leftUV_d, INV_PROJECTION_MATRIX);
	float d4 = getDepthVal(DEPTH_TEXTURE, centerUV_d, INV_PROJECTION_MATRIX);
	float d5 = getDepthVal(DEPTH_TEXTURE, rightUV_d, INV_PROJECTION_MATRIX);
	float d6 = getDepthVal(DEPTH_TEXTURE, bottomLeftUV_d, INV_PROJECTION_MATRIX);
	float d7 = getDepthVal(DEPTH_TEXTURE, bottomUV_d, INV_PROJECTION_MATRIX);
	float d8 = getDepthVal(DEPTH_TEXTURE, bottomRightUV_d, INV_PROJECTION_MATRIX);
	
	float edgeDepth = 0.0;
	if (depth_use_laplace) {
		 edgeDepth = (8.0 * d4 - (d0+d1+d2+d3+d5+d6+d7+d8)) * depth_multiplier;
	}
	else {
		float d_sobel_edge_h = (d2 + (2.0*d5) + d8 - (d0 + (2.0*d3) + d6)) / 4.0;
  		float d_sobel_edge_v = (d0 + (2.0*d1) + d2 - (d6 + (2.0*d7) + d8)) / 4.0;
		edgeDepth = sqrt((d_sobel_edge_h * d_sobel_edge_h) + (d_sobel_edge_v * d_sobel_edge_v)) * depth_multiplier;
	}
	
	
	float depthThreshold = depth_threshold * d0;
	edgeDepth = smoothstep(depthThreshold-depthThreshold/5.0, depthThreshold, edgeDepth);
	
	float edgeVal = edgeDepth;
	
	vec4 n0 = texture(SCREEN_TEXTURE, topLeftUV_c);
	vec4 n1 = texture(SCREEN_TEXTURE, topUV_c);
	vec4 n2 = texture(SCREEN_TEXTURE, topRightUV_c);
	vec4 n3 = texture(SCREEN_TEXTURE, leftUV_c);
	vec4 n4 = texture(SCREEN_TEXTURE, centerUV_c);
	vec4 n5 = texture(SCREEN_TEXTURE, rightUV_c);
	vec4 n6 = texture(SCREEN_TEXTURE, bottomLeftUV_c);
	vec4 n7 = texture(SCREEN_TEXTURE, bottomUV_c);
	vec4 n8 = texture(SCREEN_TEXTURE, bottomRightUV_c);


	float color_edge;
	
	if (color_use_laplace) {
		vec4 laplace_edge = (8.0 * n4 - (n0+n1+n2+n3+n5+n6+n7+n8));
		color_edge = laplace_edge.r;
		color_edge += laplace_edge.g;
    	color_edge +=  laplace_edge.b;
    	color_edge /= 3.0;
	}
	else {
		vec4 sobel_edge_h = (n2 + (2.0*n5) + n8 - (n0 + (2.0*n3) + n6)) / 4.0;
		vec4 sobel_edge_v = (n0 + (2.0*n1) + n2 - (n6 + (2.0*n7) + n8)) / 4.0;
		vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));
		color_edge = sobel.r;
		color_edge += sobel.g;
		color_edge +=  sobel.b;
		color_edge /= 3.0;
	}
	
	edgeVal = max(edgeVal, color_edge);
	
	if (edgeVal > edge_threshold) {
		if (use_bg_texture) {
			ALBEDO = edge_color.rgb * texture(bgTex, SCREEN_UV).rgb;
		}
		else {
			ALBEDO = edge_color.rgb;
			ALPHA = min(max_edge_alpha,edgeVal * edge_alpha_multiplier);
		}
		
	}
	else {
		if (use_bg_texture) {
			ALBEDO = texture(bgTex, SCREEN_UV).rgb;
		}
		else {
			ALPHA = 0.0;
		}
	}
}