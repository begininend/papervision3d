﻿/**
* ...
* @author John Grden
* @version 0.1
*/

package org.papervision3d.utils 
{
	import com.blitzagency.xray.logger.XrayLog;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.proto.CameraObject3D;
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.core.proto.SceneObject3D;
	import org.papervision3d.core.render.InteractiveRendererEngine;
	import org.papervision3d.core.render.hit.RenderHitData;
	import org.papervision3d.events.InteractiveScene3DEvent;
	import org.papervision3d.events.RendererEvent;
	import org.papervision3d.materials.MovieMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.utils.virtualmouse.IVirtualMouseEvent;
	import org.papervision3d.utils.virtualmouse.VirtualMouse;
	import flash.display.DisplayObject;

	public class InteractiveSceneManager extends EventDispatcher
	{
		/**
		* MOUSE_IS_DOWN is a quick static property to check and is maintained by the ISM
		*/
		public static var MOUSE_IS_DOWN								:Boolean = false;
		public static var MOUSE_IS_OVER								:Boolean = false;
		public static var MOUSE_IS_OUT								:Boolean = true;
		
		/**
		* VirtualMouse is used with faceLevelMode of ISM or DO3D's.  Its a virtual mouse that causes the objects in your materials movieclip containers to fire off their mouse events such as click, over, out, release, press etc
		 * </p>
		 * <p>
		 * Using these events requires you only to do what you normally do - establish listeners with your objects like you normally would, and you'll receive them!
		*/		
		public var virtualMouse										:VirtualMouse = new VirtualMouse();
		
		public var mouse3D											:Mouse3D = new Mouse3D();
		
		public var scene											:SceneObject3D;
		
		/**
		* Main container for ISM to create the sub InteractiveSprite containers for the faces and DO3D objects passed in during the render loop
		*/		
		public var container										:Sprite;
		
		public var camera											:CameraObject3D;
		
		public var renderHitData									:RenderHitData;	
		
		public var currentDisplayObject3D							:DisplayObject3D;
		
		public var currentMaterial									:MaterialObject3D;
		
		public var enableOverOut									:Boolean = true;
		
		public var currentMouseDO3D									:DisplayObject3D = null;
		
		public var debug											:Boolean = false;
		
		protected static var point									:Point = new Point();
		
		/**
		* @private
		*/		
		protected var log											:XrayLog = new XrayLog();
		
		public function InteractiveSceneManager(scene:SceneObject3D, container:Sprite, camera:CameraObject3D=null) 
		{
			this.scene = scene;
			this.container = container;
			this.camera = camera;
			
			init();
		}
		
		public function init():void
		{		
			if( container )
			{
				if( container.stage )
				{
					initVirtualMouse();
				}else
				{
					container.addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
				}				
			}
		}
		
		/**
		 * @private
		 * @param e
		 * 
		 */		
		protected function handleAddedToStage(e:Event):void
		{			
			initVirtualMouse();			
			initListeners();
		}
		
		protected function initVirtualMouse():void
		{
			// set the virtualMouse stage
			virtualMouse.stage = container.stage;
			virtualMouse.container = container; // might set this to stage later
		}
		
		public function initListeners():void
		{
			if( scene.interactive )
			{
				// setup listeners
				container.addEventListener(MouseEvent.MOUSE_DOWN, handleMousePress);
				container.addEventListener(MouseEvent.MOUSE_UP, handleMouseRelease);
				container.addEventListener(MouseEvent.CLICK, handleMouseClick);
				container.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			
				if( scene.renderer is InteractiveRendererEngine ) InteractiveRendererEngine(scene.renderer).addEventListener(RendererEvent.RENDER_DONE, handleRenderDone);
			}
		}
		
		protected function handleRenderDone(e:RendererEvent):void
		{
			resolveRenderHitData();
			
			currentDisplayObject3D = renderHitData.displayObject3D;
			currentMaterial = renderHitData.material;
			
			// when we move the mouse, we assess if there is need to dispatch Over/Out calls
			manageOverOut();
		}
		
		protected function manageOverOut():void
		{
			if( !enableOverOut ) return;
			
			if(renderHitData.hasHit)
			{
				if( !currentMouseDO3D && currentDisplayObject3D ) 
				{
					handleMouseOver(currentDisplayObject3D);
					currentMouseDO3D = currentDisplayObject3D;
				}
				else if( currentMouseDO3D && currentMouseDO3D != currentDisplayObject3D )
				{
					handleMouseOut(currentMouseDO3D);
					handleMouseOver(currentDisplayObject3D);
					currentMouseDO3D = currentDisplayObject3D;
				}
			}
			else
			{
				if( currentMouseDO3D != null )
				{
					handleMouseOut(currentMouseDO3D);
					currentMouseDO3D = null;
				}
			}
		}
		
		protected function resolveRenderHitData():void
		{
			point.x = container.mouseX;
			point.y = container.mouseY;

			renderHitData = InteractiveRendererEngine(scene.renderer).hitTestPoint2D(point) as RenderHitData;
		}
		
		/**
		 * Handles the MOUSE_DOWN event on an InteractiveSprite container
		 * @param e
		 * 
		 */		
		protected function handleMousePress(e:MouseEvent):void
		{
			if( e is IVirtualMouseEvent ) return;
			MOUSE_IS_DOWN = true;
			if( virtualMouse ) virtualMouse.press();
			if( renderHitData && renderHitData.hasHit ) dispatchObjectEvent(InteractiveScene3DEvent.OBJECT_PRESS, currentDisplayObject3D);
		}
		/**
		 * Handles the MOUSE_UP event on an InteractiveSprite container
		 * @param e
		 * 
		 */		
		protected function handleMouseRelease(e:MouseEvent):void
		{
			if( e is IVirtualMouseEvent ) return;
			MOUSE_IS_DOWN = false;
			if( virtualMouse ) virtualMouse.release();
			if( renderHitData && renderHitData.hasHit ) dispatchObjectEvent(InteractiveScene3DEvent.OBJECT_RELEASE, currentDisplayObject3D);
		}
		/**
		 * Handles the MOUSE_CLICK event on an InteractiveSprite container
		 * @param e
		 * 
		 */		
		protected function handleMouseClick(e:MouseEvent):void
		{
			if( e is IVirtualMouseEvent ) return;
			if( renderHitData && renderHitData.hasHit ) dispatchObjectEvent(InteractiveScene3DEvent.OBJECT_CLICK, currentDisplayObject3D);
		}
		/**
		 * Handles the MOUSE_OVER event on an InteractiveSprite container
		 * @param e
		 * 
		 */		
		
		protected function handleMouseOver(DO3D:DisplayObject3D):void
		{
			dispatchObjectEvent(InteractiveScene3DEvent.OBJECT_OVER, DO3D);
		}
		
		/**
		 * Handles the MOUSE_OUT event on an InteractiveSprite container
		 * @param e
		 * 
		 */		
		protected function handleMouseOut(DO3D:DisplayObject3D):void
		{
			if( DO3D ) 
			{
				var mat:MovieMaterial = DO3D.material as MovieMaterial;
				
				if( mat ) virtualMouse.exitContainer();
			}
			
			dispatchObjectEvent(InteractiveScene3DEvent.OBJECT_OUT, DO3D);	
		}
		/**
		 * Handles the MOUSE_MOVE event on an InteractiveSprite container
		 * @param e
		 * 
		 */		
		protected function handleMouseMove(e:MouseEvent):void
		{
			if( e is IVirtualMouseEvent ) return;
			if( virtualMouse && renderHitData )
			{
				// locate the material's movie
				var mat:MovieMaterial = currentMaterial as MovieMaterial;
				
				if( mat )
				{
					//log.debug("found moviematerial, setting as container", container.name, mat.name);
					// set the location where the calcs should be performed
					virtualMouse.container = mat.movie as Sprite;
				}
				
				// update virtual mouse so it can test
				if( virtualMouse.container ) virtualMouse.setLocation(renderHitData.u, renderHitData.v);
				
				// update the position mouse3D
				if( Mouse3D.enabled && renderHitData.renderable!=null ) mouse3D.updatePosition(renderHitData);
				
				dispatchObjectEvent(InteractiveScene3DEvent.OBJECT_MOVE, currentDisplayObject3D);

			}else if( renderHitData.hasHit )
			{
				dispatchObjectEvent(InteractiveScene3DEvent.OBJECT_MOVE, currentDisplayObject3D);
			}
			
		}
		
		/**
		 * @private
		 * @param event
		 * @param currentTarget
		 * 
		 */		
		
		protected function dispatchObjectEvent(event:String, DO3D:DisplayObject3D):void
		{
			if(debug) log.debug(event, DO3D.name);
			
			if(renderHitData.hasHit) 
			{
				var x:Number = renderHitData.u ? renderHitData.u : 0;
				var y:Number = renderHitData.v ? renderHitData.v : 0;
				dispatchEvent(new InteractiveScene3DEvent(event, DO3D, container, renderHitData.renderable as Triangle3D, x, y));
				DO3D.dispatchEvent(new InteractiveScene3DEvent(event, DO3D, container, renderHitData.renderable as Triangle3D, x, y));
			} else 
			{
				dispatchEvent(new InteractiveScene3DEvent(event, DO3D, container));
				if( DO3D ) DO3D.dispatchEvent(new InteractiveScene3DEvent(event, DO3D, container));
			}
		}
	}	
}