/proc/attempt_initiate_surgery(obj/item/I, mob/living/M, mob/user)
	if(istype(M))
		var/mob/living/carbon/human/H
		var/obj/item/organ/limb/affecting
		var/selected_zone = user.zone_sel.selecting

		if(istype(M, /mob/living/carbon/human))
			H = M
			affecting = H.get_organ(check_zone(selected_zone))

		if(M.lying || isslime(M))	//if they're prone or a slime
			var/datum/surgery/current_surgery

			for(var/datum/surgery/S in M.surgeries)
				if(S.location == selected_zone)
					current_surgery = S

			if(!current_surgery)
				var/list/all_surgeries = surgeries_list.Copy()
				var/list/available_surgeries = list()

				for(var/datum/surgery/S in all_surgeries)
					if(!S.possible_locs.Find(selected_zone))
						continue
					if(affecting && S.requires_organic_bodypart && affecting.status == ORGAN_ROBOTIC)
						continue
					if(!S.can_start(user, M))
						continue

					for(var/path in S.species)
						if(istype(M, path))
							available_surgeries[S.name] = S
							break

				var/P = input("Begin which procedure?", "Surgery", null, null) as null|anything in available_surgeries
				if(P && user && user.Adjacent(M) && (I in user))
					var/datum/surgery/S = available_surgeries[P]
					var/datum/surgery/procedure = new S.type
					if(procedure)
						procedure.location = selected_zone
						if(procedure.ignore_clothes || get_location_accessible(M, selected_zone))
							M.surgeries += procedure
							procedure.organ = affecting
							user.visible_message("[user] drapes [I] over [M]'s [parse_zone(selected_zone)] to prepare for \an [procedure.name].", \
								"<span class='notice'>You drape [I] over [M]'s [parse_zone(selected_zone)] to prepare for \an [procedure.name].</span>")

							add_logs(user, M, "operated", addition="Operation type: [procedure.name], location: [selected_zone]")
						else
							user << "<span class='warning'>You need to expose [M]'s [parse_zone(selected_zone)] first!</span>"

			else if(!current_surgery.step_in_progress)
				if(current_surgery.status == 1)
					M.surgeries -= current_surgery
					user.visible_message("[user] removes the drapes from [M]'s [parse_zone(selected_zone)].", \
						"<span class='notice'>You remove the drapes from [M]'s [parse_zone(selected_zone)].</span>")
					qdel(current_surgery)
				else if(istype(user.get_inactive_hand(), /obj/item/weapon/cautery) && current_surgery.can_cancel)
					M.surgeries -= current_surgery
					user.visible_message("[user] mends the incision and removes the drapes from [M]'s [parse_zone(selected_zone)].", \
						"<span class='notice'>You mend the incision and remove the drapes from [M]'s [parse_zone(selected_zone)].</span>")
					qdel(current_surgery)
				else if(current_surgery.can_cancel)
					user << "<span class='warning'>You need to hold a cautery in inactive hand to stop [M]'s surgery!</span>"


			return 1
	return 0



proc/get_location_modifier(mob/M)
	var/turf/T = get_turf(M)
	if(locate(/obj/structure/table/optable, T))
		return 1
	else if(locate(/obj/structure/table, T))
		return 0.8
	else if(locate(/obj/structure/bed, T))
		return 0.7
	else
		return 0.5


/proc/get_location_accessible(mob/M, location)
	var/covered_locations	= 0	//based on body_parts_covered
	var/face_covered		= 0	//based on flags_inv
	var/eyesmouth_covered	= 0	//based on flags
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		for(var/obj/item/clothing/I in list(C.back, C.wear_mask, C.head))
			covered_locations |= I.body_parts_covered
			face_covered |= I.flags_inv
			eyesmouth_covered |= I.flags_cover
		if(ishuman(C))
			var/mob/living/carbon/human/H = C
			for(var/obj/item/I in list(H.wear_suit, H.w_uniform, H.shoes, H.belt, H.gloves, H.glasses, H.ears))
				covered_locations |= I.body_parts_covered
				face_covered |= I.flags_inv
				eyesmouth_covered |= I.flags_cover

	switch(location)
		if("head")
			if(covered_locations & HEAD)
				return 0
		if("eyes")
			if(covered_locations & HEAD || face_covered & HIDEEYES || eyesmouth_covered & GLASSESCOVERSEYES)
				return 0
		if("mouth")
			if(covered_locations & HEAD || face_covered & HIDEFACE || eyesmouth_covered & MASKCOVERSMOUTH || eyesmouth_covered & HEADCOVERSMOUTH)
				return 0
		if("chest")
			if(covered_locations & CHEST)
				return 0
		if("groin")
			if(covered_locations & GROIN)
				return 0
		if("l_arm")
			if(covered_locations & ARM_LEFT)
				return 0
		if("r_arm")
			if(covered_locations & ARM_RIGHT)
				return 0
		if("l_leg")
			if(covered_locations & LEG_LEFT)
				return 0
		if("r_leg")
			if(covered_locations & LEG_RIGHT)
				return 0
		if("l_hand")
			if(covered_locations & HAND_LEFT)
				return 0
		if("r_hand")
			if(covered_locations & HAND_RIGHT)
				return 0
		if("l_foot")
			if(covered_locations & FOOT_LEFT)
				return 0
		if("r_foot")
			if(covered_locations & FOOT_RIGHT)
				return 0

	return 1

