// handlers/memberLeave.js
const { EmbedBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle } = require("discord.js");
const fetch = require("node-fetch");

const api = async (ep, method="GET", body=null) => {
  const opts = { method, headers:{"Content-Type":"application/json","x-bot-secret":process.env.BOT_SECRET} };
  if (body) opts.body = JSON.stringify(body);
  return (await fetch(process.env.BACKEND_URL+ep, opts)).json();
};

async function handleMemberLeave(member, client) {
  if (member.guild.id !== process.env.GUILD_ID) return;
  const discordId  = member.id;
  const discordTag = member.user.username || "Unknown";

  try {
    const status = await api(`/api/license/by-discord/${discordId}`);
    const active  = (status.licenses||[]).filter(l => l.is_active && !l.is_tampered);
    if (!active.length) return;

    await api("/api/license/tamper","POST",{ discord_id:discordId, tamper_reason:"Developer left Discord server" });
    const placeIds = active.map(l => l.place_id);

    const embed = new EmbedBuilder().setColor(0xFF4444)
      .setTitle("⚠️ LICENSE TAMPERED — Developer Keluar Server")
      .setDescription("Seorang developer VEX meninggalkan server. Semua license mereka **dinonaktifkan otomatis**.")
      .addFields(
        {name:"👤 Developer", value:`**${discordTag}**\nID: \`${discordId}\``, inline:true},
        {name:"⏰ Waktu",     value:`<t:${Math.floor(Date.now()/1000)}:F>`, inline:true},
        {name:`🎮 Place IDs (${placeIds.length})`, value:placeIds.map(id=>`\`${id}\``).join("\n")||"—"},
        {name:"📋 Info", value:"• Game yang pakai license ini akan error saat restart\n• Developer harus rejoin & `/renewal` untuk aktifkan kembali"}
      )
      .setThumbnail(member.user.displayAvatarURL({dynamic:true}))
      .setFooter({text:"VEX Anti-Cheat • Auto License Enforcement"}).setTimestamp();

    const row = new ActionRowBuilder().addComponents(
      new ButtonBuilder().setLabel("🔄 Restore").setCustomId(`restore_${discordId}`).setStyle(ButtonStyle.Secondary),
      new ButtonBuilder().setLabel("🗑️ Hapus Permanen").setCustomId(`delete_${discordId}`).setStyle(ButtonStyle.Danger)
    );

    const ch = await client.channels.fetch(process.env.ADMIN_CHANNEL_ID).catch(()=>null);
    if (ch) await ch.send({
      content:`🚨 <@&${process.env.ADMIN_ROLE_ID}> <@${process.env.OWNER_DISCORD_ID}> License enforcement triggered!`,
      embeds:[embed], components:[row]
    });

    await member.user.send({ embeds:[new EmbedBuilder().setColor(0xFF8800)
      .setTitle("🛡️ VEX Anti-Cheat — License Nonaktif")
      .setDescription(`Kamu meninggalkan server Discord VEX. Semua license kamu **dinonaktifkan**.`)
      .addFields(
        {name:"Place IDs", value:placeIds.map(id=>`\`${id}\``).join("\n")||"—"},
        {name:"Cara Reaktivasi", value:"1. Rejoin server Discord VEX\n2. `/renewal <placeId>` untuk tiap Place ID\n3. Update Secret Key di Studio & publish ulang"}
      ).setFooter({text:"VEX Anti-Cheat"}).setTimestamp()]
    }).catch(()=>{});

  } catch(e) { console.error("[VEX LEAVE]", e.message); }
}

async function handleMemberLeaveButtons(interaction) {
  if (!interaction.isButton()) return;
  const { customId } = interaction;
  const isAdmin = interaction.member.roles.cache.has(process.env.ADMIN_ROLE_ID) || interaction.user.id === process.env.OWNER_DISCORD_ID;
  if (!isAdmin) return interaction.reply({content:"❌ Hanya admin.", ephemeral:true});

  if (customId.startsWith("restore_")) {
    await interaction.deferReply({ephemeral:true});
    const id = customId.replace("restore_","");
    const r  = await api("/api/license/restore","POST",{discord_id:id});
    await interaction.editReply({content: r.success ? `✅ Restored \`${id}\`. Developer perlu /renewal.` : `❌ ${r.error}`});
  }
  if (customId.startsWith("delete_")) {
    await interaction.deferReply({ephemeral:true});
    const id = customId.replace("delete_","");
    await api(`/api/admin/developer/${id}`,"DELETE");
    await interaction.editReply({content:`🗑️ Data developer \`${id}\` dihapus permanen.`});
  }
}

module.exports = { handleMemberLeave, handleMemberLeaveButtons };
