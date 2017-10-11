# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module UploaderReferenceCounter

  #Uses the reference_counter field when calling store! and remove! methods of Uploader	
	
  #return mount_uploader name of the model
  def uploader
    model.mount_uploader_name	  
  end

  def store!
    #check if there is an previous image
    old_image = nil
    if defined? model.send("#{uploader}_was").file.file
      old_image = model.send("#{uploader}_was").file.file	    	    
    end

    if old_image
      if old_image.medium_hash.downcase != model.send("#{uploader}_before_type_cast").downcase	      
        #remove the old image
	model.send("#{uploader}_was").remove!
      else
	#the new image is the same as the old image. nothing needs to be done       
        return
      end
    end

    #call the super class store! method to store the image. The super will create a new
    #image in database only if there is no object with same hash and file termination 
    super
   
    #after the super is called, an image object is created 
    image = model.send("#{uploader}").file.file

    #increase the reference_counter of the stored image and save 
    image.reference_counter += 1
    image.save
  end

  def remove!
    image = nil

    #there is an image in this model? 
    if defined? model.send("#{uploader}_was").file.file	    
      #model is being updated	    
      image = model.send("#{uploader}_was").file.file           
    elsif defined? model.send("#{uploader}").file.file	    
      #model is being deleted 	    
      image = model.send("#{uploader}").file.file 
    end	      

    if image
      #if there is an image, decrease reference_counter of image or remove it	    
      if image.reference_counter > 1
	#only decrease the counter and save      
        image.reference_counter -= 1
	image.save 
      else
	#call the super class remove! method to remove the image      
        super
      end	
    end
  end

end
