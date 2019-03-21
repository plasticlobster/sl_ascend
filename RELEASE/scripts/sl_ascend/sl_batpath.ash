script "sl_batpath.ash"

void bat_startAscension()
{
	if(my_path() == "Dark Gyffte") {
		visit_url("choice.php?whichchoice=1343&option=1");
		bat_reallyPickSkills(20);
	}
}
void bat_initializeSettings()
{
	if(my_path() == "Dark Gyffte")
	{
		set_property("sl_100familiar", $familiar[Egg Benedict]);
		set_property("sl_cubeItems", false);
		set_property("sl_getSteelOrgan", false);
		set_property("sl_grimstoneFancyOilPainting", false);
		set_property("sl_grimstoneOrnateDowsingRod", false);
		set_property("sl_paranoia", 10);
		set_property("sl_useCubeling", false);
		set_property("sl_wandOfNagamar", false);
		set_property("sl_getStarKey", true);
		set_property("sl_bat_desiredForm", "");
	}
}

// The following functions set the desired form.
// The pre-adventure handler adjusts our actual form to match.
// This is done to avoid getting stuck in an incorrect form,
// or wasting HP switching back and forth.

void bat_formNone()
{
	if(my_class() != $class[Vampyre]) return;
	if(get_property("sl_bat_desiredForm") != "")
	{
		set_property("sl_bat_desiredForm", "");
	}
}

void bat_formWolf()
{
	if(my_class() != $class[Vampyre]) return;
	set_property("sl_bat_desiredForm", "wolf");
	bat_switchForm($effect[Wolf Form]);
}

void bat_formMist()
{
	if(my_class() != $class[Vampyre]) return;
	set_property("sl_bat_desiredForm", "mist");
	bat_switchForm($effect[Mist Form]);
}

void bat_formBats()
{
	if(my_class() != $class[Vampyre]) return;
	set_property("sl_bat_desiredForm", "bats");
	bat_switchForm($effect[Bats Form]);
}

void bat_clearForms()
{
	foreach ef in $effects[Wolf Form, Mist Form, Bats Form]
	{
		if (0 != have_effect(ef)) {
			use_skill(to_skill(ef));
		}
	}
}

boolean bat_switchForm(effect form)
{
	if (0 != have_effect(form)) return true;
	if(!have_skill(form.to_skill()))
	{
		bat_clearForms();
		return false;
	}
	if (my_hp() <= 10)
	{
		print("We don't have enough HP to switch form to " + form + "!", "red");
		return false;
	}
	return use_skill(1, form.to_skill());
}

boolean bat_formPreAdventure()
{
	if(my_class() != $class[Vampyre]) return false;

	string desiredForm = get_property("sl_bat_desiredForm");
	effect form;
	switch(desiredForm)
	{
	case "wolf":
		return bat_switchForm($effect[Wolf Form]);
	case "mist":
		return bat_switchForm($effect[Mist Form]);
	case "bats":
		return bat_switchForm($effect[Bats Form]);
	case "":
		bat_clearForms();
		return true;
	default:
		print("sl_bat_desiredForm was set to bad value: '" + desiredForm + "'. Should be '', 'wolf', 'mist', or 'bats'.", "red");
		set_property("sl_bat_desiredForm", "");
		return false;
	}
}

void bat_initializeSession()
{
	if(my_class() == $class[Vampyre])
	{
		set_property("sl_mpAutoRecovery", get_property("mpAutoRecovery"));
		set_property("sl_mpAutoRecoveryTarget", get_property("mpAutoRecoveryTarget"));
		set_property("mpAutoRecovery", -0.05);
		set_property("mpAutoRecoveryTarget", 0.0);
	}
}

void bat_terminateSession()
{
	if(my_class() == $class[Vampyre])
	{
		set_property("mpAutoRecovery", get_property("sl_mpAutoRecovery"));
		set_property("sl_mpAutoRecovery", 0.0);
		set_property("mpAutoRecoveryTarget", get_property("sl_mpAutoRecoveryTarget"));
		set_property("sl_mpAutoRecoveryTarget", 0.0);
	}
}

void bat_initializeDay(int day)
{
	if(my_path() != "Dark Gyffte")
	{
		return;
	}

	if(get_property("sl_day_init").to_int() < day)
	{
		set_property("_sl_bat_bloodBank", 0); // 0: no blood yet, 1: base blood, 2: intimidating blood
		set_property("sl_bat_ensorcels", 0);
		set_property("sl_bat_howls", 0);
		set_property("sl_bat_howled", "");
		set_property("sl_bat_soulmonster", "");
		bat_tryBloodBank();
		if (bat_shouldPickSkills(20))
		{
			bat_reallyPickSkills(20);
		}
	}
}

int bat_maxHPCost(skill sk)
{
	switch(sk)
	{
		case $skill[Baleful Howl]:
		case $skill[Intimidating Aura]:
		case $skill[Mist Form]:
		case $skill[Sharp Eyes]:
			return 30;
		case $skill[Madness of Untold Aeons]:
			return 25;
		case $skill[Crush]:
		case $skill[Wolf Form]:
		case $skill[Blood Spike]:
		case $skill[Blood Cloak]:
		case $skill[Macabre Cunning]:
		case $skill[Piercing Gaze]:
		case $skill[Ensorcel]:
		case $skill[Flock of Bats Form]:
			return 20;
		case $skill[Ceaseless Snarl]:
		case $skill[Preternatural Strength]:
		case $skill[Blood Chains]:
		case $skill[Sanguine Magnetism]:
		case $skill[Perceive Soul]:
		case $skill[Sinister Charm]:
		case $skill[Batlike Reflexes]:
		case $skill[Spot Weakness]:
			return 15;
		case $skill[Savage Bite]:
		case $skill[Ferocity]:
		case $skill[Chill of the Tomb]:
		case $skill[Spectral Awareness]:
			return 10;
		case $skill[Flesh Scent]:
		case $skill[Hypnotic Eyes]:
			return 5;
		default:
			return 0;
	}
}

int bat_baseHP()
{
	return 20 * get_property("darkGyfftePoints").to_int() + my_basestat($stat[Muscle]) + 20;
}

int bat_remainingBaseHP()
{
	int baseHP = bat_baseHP();
	foreach sk in $skills[]
	{
		// important that this uses have_skill and not sl_have_skill, as sl_have_skill would
		// report incorrectly if any form intrinsics are active
		if(have_skill(sk))
			baseHP -= bat_maxHPCost(sk);
	}
	return baseHP;
}

// to be called when already in Torpor
skill [int] bat_pickSkills(int hpLeft)
{
	int costSoFar = 0;
	int baseHP = bat_baseHP();
	skill [int] picks;

	boolean addPick(skill sk)
	{
		if(baseHP - costSoFar - bat_maxHPCost(sk) < hpLeft)
			return false;
		costSoFar += bat_maxHPCost(sk);
		picks[picks.count()] = sk;
		return true;
	}

	if(get_property("_sl_bat_bloodBank") != "2")
		addPick($skill[Intimidating Aura]);

	foreach sk in $skills[
		Chill of the Tomb,
		Blood Chains,
		Madness of Untold Aeons,
		Sinister Charm,
		Blood Cloak,
		Baleful Howl,
		Perceive Soul,
		Hypnotic Eyes,
		Ensorcel,
		Sharp Eyes,
		Batlike Reflexes,
		Ceaseless Snarl,
		Flock of Bats Form,
		Mist Form,
		Sanguine Magnetism,
		Macabre Cunning,
		Ferocity,
		Flesh Scent,
		Wolf Form,
		Spot Weakness,
		Preternatural Strength,
		Savage Bite,
		Spectral Awareness,
		Piercing Gaze,
		Blood Spike,
	]
	{
		addPick(sk);
	}
	return picks;
}

void bat_reallyPickSkills(int hpLeft)
{
	visit_url("main.php"); // check if we're already in Torpor
	if(last_choice() != 1342)
		visit_url("campground.php?action=coffin");

	skill [int] picks = bat_pickSkills(hpLeft);
	string url = "choice.php?whichchoice=1342&option=2&pwd=" + my_hash();
	foreach i,sk in picks
	{
		url += "&sk[]=";
		url += sk.to_int() - 24000;
	}
	visit_url(url);
	visit_url("choice.php?whichchoice=1342&option=1&pwd=" + my_hash());
}

boolean bat_shouldPickSkills(int hpLeft)
{
	skill [int] picks = bat_pickSkills(hpLeft);

	foreach sk in $skills[]
	{
		if(sk.bat_maxHPCost() == 0)
			continue;

		boolean found = false;

		foreach i,pick in picks
		{
			if(sk == pick)
			{
				found = true;
				break;
			}
		}

		if(found != have_skill(sk))
			return true;
	}

	return false;
}

boolean bat_shouldEnsorcel(monster m)
{
	if(my_class() != $class[Vampyre] || !sl_have_skill($skill[Ensorcel]))
		return false;

	// until we have a way to tell what we already have as an ensorcelee, just ensorcel goblins
	// to help avoid getting beaten up...
	if(m.monster_phylum() == $phylum[goblin] && !isFreeMonster(m))
		return true;

	return false;
}

boolean bat_consumption()
{
	if(my_class() != $class[Vampyre])
		return false;

	if(have_outfit("War Hippy Fatigues"))
	{
		sell($item[padl phone].buyer, item_amount($item[padl phone]), $item[padl phone]);
		sell($item[red class ring].buyer, item_amount($item[red class ring]), $item[red class ring]);
		sell($item[blue class ring].buyer, item_amount($item[blue class ring]), $item[blue class ring]);
		sell($item[white class ring].buyer, item_amount($item[white class ring]), $item[white class ring]);
	}
	if(have_outfit("Frat Warrior Fatigues"))
	{
		sell($item[pink clay bead].buyer, item_amount($item[pink clay bead]), $item[pink clay bead]);
		sell($item[purple clay bead].buyer, item_amount($item[purple clay bead]), $item[purple clay bead]);
		sell($item[green clay bead].buyer, item_amount($item[green clay bead]), $item[green clay bead]);
		sell($item[communications windchimes].buyer, item_amount($item[communications windchimes]), $item[communications windchimes]);
	}

	boolean consume_first(boolean [item] its)
	{
		foreach it in its
		{
			if(creatable_amount(it) > 0 || available_amount(it) > 0)
			{
				if (available_amount(it) == 0)
					create(1, it);
				if(it.fullness > 0)
					ccEat(1, it);
				else if(it.inebriety > 0)
					ccDrink(1, it);
				else if(it.spleen > 0)
					ccChew(1, it);
				else
				{
					print("Woah, I made a " + it + " to consume, but you can't consume that?", "red");
					return false;
				}
				return true;
			}
		}
		return false;
	}

	if ((my_level() >= 7) &&
		(spleen_left() >= 3) &&
		(fullness_left() >= 2) &&
		(item_amount($item[dieting pill]) > 0) &&
		((item_amount($item[blood-soaked sponge cake]) > 0) ||
		 (item_amount($item[blood bag]) > 0 && (1 <= item_amount($item[filthy poultice]) + item_amount($item[gauze garter])))))
	{
		ccChew(1, $item[dieting pill]);
		if (item_amount($item[blood-soaked sponge cake]) == 0)
			create(1, $item[blood-soaked sponge cake]);
		ccEat(1, $item[blood-soaked sponge cake]);
		return true;
	}
	if (my_adventures() <= 5 && item_amount($item[blood bag]) > 0)
	{
		if (inebriety_left() > 0)
		{
			pullXWhenHaveY($item[monstar energy beverage], 1, 0);
			// don't auto consume bottle of Sanguiovese, only drink those if we're down to one adventure
			if(consume_first($items[vampagne, dusty bottle of blood, Red Russian, mulled blood]))
				return true;
		}
		if (fullness_left() > 0)
		{
			pullXWhenHaveY($item[gauze garter], 1, 0);
			// don't auto consume bloodstick, only eat those if we're down to one adventure AFTER booze
			if(consume_first($items[blood-soaked sponge cake, blood roll-up, blood snowcone, actual blood sausage, ]))
				return true;
		}
	}

	if(my_adventures() <= 1)
	{
		if (fullness_left() > 0)
		{
			if (consume_first($items[bloodstick]))
				return true;
		}
		if(inebriety_left() > 0)
		{
			if (consume_first($items[bottle of Sanguiovese]))
				return true;
		}
	}

	return true;
}

boolean bat_skillValid(skill sk)
{
	if($skills[Savage Bite, Crush, Baleful Howl, Ceaseless Snarl] contains sk && have_effect($effect[Bats Form]) + have_effect($effect[Mist Form]) > 0)
		return false;

	if($skills[Blood Spike, Blood Chains, Chill of the Tomb, Blood Cloak] contains sk && have_effect($effect[Wolf Form]) + have_effect($effect[Bats Form]) > 0)
		return false;

	if($skills[Piercing Gaze, Perceive Soul, Ensorcel, Spectral Awareness] contains sk && have_effect($effect[Wolf Form]) + have_effect($effect[Mist Form]) > 0)
		return false;

	return true;
}

boolean bat_tryBloodBank()
{
	int bloodBank = get_property("_sl_bat_bloodBank").to_int();
	if(bloodBank == 0 || (bloodBank == 1 && have_skill($skill[Intimidating Aura])))
	{
		visit_url("place.php?whichplace=town_right&action=town_bloodbank");
		set_property("_sl_bat_bloodBank", (have_skill($skill[Intimidating Aura]) ? 2 : 1));
		return true;
	}

	return false;
}

boolean LM_batpath()
{
	if(my_class() != $class[Vampyre])
		return false;

	if(bat_remainingBaseHP() >= 70 && bat_shouldPickSkills(20))
	{
		bat_reallyPickSkills(20);
		return true;
	}
	bat_tryBloodBank();
	return false;
}
